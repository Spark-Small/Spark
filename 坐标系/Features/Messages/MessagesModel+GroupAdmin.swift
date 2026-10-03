//
//  MessagesModel+GroupAdmin.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    func updateAnnouncement(_ text: String, for conversationID: ChatConversation.ID) {
        guard let index = index(of: conversationID) else { return }
        conversations[index].announcement = text.trimmingCharacters(in: .whitespacesAndNewlines)
        appendSystemTip(MessagesCopy.announcementUpdated, audience: .everyone, to: conversationID)
    }

    func renameGroup(_ title: String, for conversationID: ChatConversation.ID) {
        guard let index = index(of: conversationID) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        conversations[index].title = trimmed
        appendSystemTip(MessagesCopy.groupRenamed(trimmed), audience: .everyone, to: conversationID)
    }

    /// 清空聊天记录（保留会话入口）
    func clearChatHistory(in conversationID: ChatConversation.ID) {
        threads[conversationID] = []
        guard let index = index(of: conversationID) else {
            persist()
            return
        }
        conversations[index].lastMessage = MessagesCopy.clearedHistoryPreview
        conversations[index].lastMessageIsMe = false
        conversations[index].updatedAt = .now
        conversations[index].unreadCount = 0
        persist()
        onConversationsChanged?()
    }

    /// 成员退出自建群：写入退群提示后从本机移除会话。
    func leavePeerGroup(conversationID: ChatConversation.ID, leaverName: String) {
        guard let conversation = conversations.first(where: {
            $0.id == conversationID && $0.isPeerGroup
        }) else { return }
        let name = leaverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipName = name.isEmpty ? MessagesCopy.memberFallback : name
        appendSystemTip(MessagesCopy.memberLeft(tipName), audience: .everyone, to: conversation.id)
        delete(conversation.id)
        onConversationsChanged?()
    }

    /// 群主解散自建群 / 活动群（本机移除会话）。
    func dissolveGroup(conversationID: ChatConversation.ID) {
        delete(conversationID)
        onConversationsChanged?()
    }

    func kickMember(_ name: String, from conversationID: ChatConversation.ID) {
        removeMember(name, from: conversationID)
    }

    func addMember(_ name: String, to conversationID: ChatConversation.ID) {
        inviteMembers([name], to: conversationID)
    }

    func inviteMembers(_ nicknames: [String], to conversationID: ChatConversation.ID) {
        let result = groupAdminService.inviteMembers(
            existing: groupMembers(for: conversationID),
            nicknames: nicknames
        )
        applyGroupMemberMutation(result, to: conversationID)
    }

    func removeMember(_ name: String, from conversationID: ChatConversation.ID) {
        let result = groupAdminService.removeMember(
            existing: groupMembers(for: conversationID),
            nickname: name
        )
        applyGroupMemberMutation(result, to: conversationID)
    }

    func addGroupAdmin(_ name: String, in conversationID: ChatConversation.ID) {
        let result = groupAdminService.updateRole(
            existing: groupMembers(for: conversationID),
            nickname: name,
            role: .admin
        )
        applyGroupMemberMutation(result, to: conversationID)
    }

    func removeGroupAdmin(_ name: String, in conversationID: ChatConversation.ID) {
        let result = groupAdminService.updateRole(
            existing: groupMembers(for: conversationID),
            nickname: name,
            role: .member
        )
        applyGroupMemberMutation(result, to: conversationID)
    }

    func transferGroupOwnership(to name: String, in conversationID: ChatConversation.ID) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        var next = groupMembers(for: conversationID).map { member -> GroupMemberRecord in
            var updated = member
            if member.role == .owner {
                updated.role = .member
            }
            if member.nickname.caseInsensitiveCompare(trimmed) == .orderedSame {
                updated.role = .owner
            }
            return updated
        }
        if !next.contains(where: { $0.nickname.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            next.append(GroupMemberRecord(nickname: trimmed, role: .owner))
        }
        groupMembersByConversation[conversationID] = next
        if let index = index(of: conversationID) {
            conversations[index].ownerName = trimmed
            conversations[index].memberNames = next.map(\.nickname)
        }
        appendSystemTip("\(trimmed)成为新群主", audience: .everyone, to: conversationID)
    }

    private func applyGroupMemberMutation(
        _ result: GroupMemberMutationResult,
        to conversationID: ChatConversation.ID
    ) {
        groupMembersByConversation[conversationID] = result.members
        if let index = index(of: conversationID) {
            conversations[index].memberNames = result.members.map(\.nickname)
        }
        if let tip = result.systemMessage, !tip.isEmpty {
            appendSystemTip(tip, audience: .everyone, to: conversationID)
        } else {
            persist()
        }
    }
}
