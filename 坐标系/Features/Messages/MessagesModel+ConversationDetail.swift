//
//  MessagesModel+ConversationDetail.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    /// 对指定观众可见的消息（退群小字仅群主可见）
    func visibleMessages(
        for id: ChatConversation.ID,
        viewerName: String,
        ownerName: String?
    ) -> [ChatMessage] {
        let isOwner = ownerName.map {
            $0.caseInsensitiveCompare(viewerName) == .orderedSame
        } ?? false
        return (threads[id] ?? []).filter { message in
            guard message.isSystem, message.systemAudience == .hostOnly else { return true }
            return isOwner
        }
    }

    /// 会话详情分页窗口内的消息（默认最近 `MessagingDeliveryPolicy.pageSize` 条）。
    func displayedMessages(
        for id: ChatConversation.ID,
        viewerName: String,
        ownerName: String?
    ) -> [ChatMessage] {
        let all = visibleMessages(for: id, viewerName: viewerName, ownerName: ownerName)
        let limit = messagePageLimitByConversation[id] ?? MessagingDeliveryPolicy.pageSize
        guard all.count > limit else { return all }
        return Array(all.suffix(limit))
    }

    func hasOlderMessages(
        in id: ChatConversation.ID,
        viewerName: String,
        ownerName: String?
    ) -> Bool {
        let allCount = visibleMessages(for: id, viewerName: viewerName, ownerName: ownerName).count
        let limit = messagePageLimitByConversation[id] ?? MessagingDeliveryPolicy.pageSize
        return allCount > limit
    }

    func loadOlderMessages(in id: ChatConversation.ID) {
        let allCount = (threads[id] ?? []).count
        let current = messagePageLimitByConversation[id] ?? MessagingDeliveryPolicy.pageSize
        messagePageLimitByConversation[id] = min(allCount, current + MessagingDeliveryPolicy.pageSize)
    }

    func groupMembers(for id: ChatConversation.ID) -> [GroupMemberRecord] {
        groupMembersByConversation[id]
            ?? groupAdminService.bootstrapMembers(
                ownerName: conversations.first(where: { $0.id == id })?.ownerName,
                memberNames: conversations.first(where: { $0.id == id })?.memberNames ?? []
            )
    }

    func groupAlias(for nickname: String, in conversationID: ChatConversation.ID) -> String? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        return groupMembers(for: conversationID).first {
            $0.nickname.caseInsensitiveCompare(name) == .orderedSame
        }?.groupAlias
    }

    /// 设置成员在本群的昵称；传空字符串表示清除群昵称
    func setGroupAlias(_ alias: String, forMember nickname: String, in conversationID: ChatConversation.ID) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if groupMembersByConversation[conversationID] == nil {
            _ = groupMembers(for: conversationID)
        }
        let trimmed = alias.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextAlias: String? = trimmed.isEmpty ? nil : trimmed
        groupMembersByConversation[conversationID] = groupMembers(for: conversationID).map { member in
            guard member.nickname.caseInsensitiveCompare(name) == .orderedSame else { return member }
            var updated = member
            updated.groupAlias = nextAlias
            return updated
        }
        persist()
    }

    func role(of nickname: String, in conversationID: ChatConversation.ID) -> GroupMemberRole {
        groupMembers(for: conversationID).first {
            $0.nickname.caseInsensitiveCompare(nickname) == .orderedSame
        }?.role ?? .member
    }

    func activeCall(for conversationID: ChatConversation.ID) -> CallSessionRecord? {
        callRecords
            .filter { $0.conversationID == conversationID && $0.status.isLive }
            .sorted { $0.startedAt > $1.startedAt }
            .first
    }

    func recentCalls(for conversationID: ChatConversation.ID) -> [CallSessionRecord] {
        callRecords
            .filter { $0.conversationID == conversationID }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func transfers(for conversationID: ChatConversation.ID) -> [TransferRecord] {
        self.transferRecords
            .filter { $0.conversationID == conversationID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func transferRecord(for message: ChatMessage) -> TransferRecord? {
        if let transferID = message.transferID {
            return transferRecords.first { $0.id == transferID }
        }
        guard let amount = message.transferAmount else { return nil }
        return transferRecords.first {
            $0.messageID == message.id || ($0.amount == amount && $0.createdAt == message.sentAt)
        }
    }

    func requestSourceLabel(for conversation: ChatConversation) -> String {
        messageRequestService.requestSource(for: conversation).rawValue
    }

    func requestPreview(for conversation: ChatConversation) -> String {
        messageRequestService.requestPreview(for: conversation)
    }
}
