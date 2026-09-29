//
//  MessagesModel+GroupChat.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    /// 活动群：一场局一个群；发起人为群主。进群用系统小字，不发问候气泡。
    @discardableResult
    func startGroupChat(
        for activity: Activity,
        role: GroupChatJoinRole = .participant,
        memberName: String = "",
        announceMembership: Bool = false
    ) -> ChatConversation? {
        let displayName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = conversations.first(where: {
            $0.kind == .activity && (
                $0.relatedActivityID == activity.id
                    || ($0.relatedActivityID == nil && $0.title == activity.title)
            )
        }) {
            syncGroupMetadata(conversationID: existing.id, activity: activity)
            if announceMembership, role == .participant, !displayName.isEmpty {
                addMember(displayName, to: existing.id)
            }
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let welcome = MessagesCopy.activityGroupWelcome(title: activity.title)
        var initialMessages = [ChatMessage.systemTip(welcome, audience: .everyone)]
        let tip: String
        switch role {
        case .host:
            tip = welcome
        case .participant:
            if !displayName.isEmpty {
                let joinTip = MessagesCopy.memberJoined(displayName)
                initialMessages.append(ChatMessage.systemTip(joinTip, audience: .everyone))
                tip = joinTip
            } else {
                tip = welcome
            }
        }
        let conversation = ChatConversation(
            id: id,
            title: activity.title,
            subtitle: MessagesCopy.activityGroupSubtitleLine(eventAt: activity.date),
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .activity,
            eventAt: activity.date,
            relatedActivityID: activity.id,
            lastMessageIsMe: false,
            ownerName: activity.hostName,
            memberNames: {
                var names = [activity.hostName]
                if role == .participant, !displayName.isEmpty,
                   displayName.caseInsensitiveCompare(activity.hostName) != .orderedSame {
                    names.append(displayName)
                }
                return names
            }()
        )
        conversations.insert(conversation, at: 0)
        threads[id] = initialMessages
        storeBootstrapMembers(for: conversation)
        persist()
        onConversationsChanged?()
        return conversation
    }

    /// 兴趣圈子群：加入圈子后进入；一圈子一群。
    @discardableResult
    func startCircleChat(
        for circle: InterestCircle,
        memberName: String = ""
    ) -> ChatConversation? {
        let displayName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = conversations.first(where: {
            $0.kind == .circle && (
                $0.relatedCircleID == circle.id
                    || ($0.relatedCircleID == nil && $0.title == circle.name)
            )
        }) {
            if !displayName.isEmpty {
                addMember(displayName, to: existing.id)
            }
            // Sync announcement / mute prefs lightly
            if let index = conversations.firstIndex(where: { $0.id == existing.id }) {
                conversations[index].announcement = circle.summary
                let memberCount = max(conversations[index].memberNames.count, circle.memberCount)
                conversations[index].subtitle = MessagesCopy.circleGroupSubtitleLine(memberCount: memberCount)
            }
            persist()
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let tip = displayName.isEmpty
            ? MessagesCopy.groupCreated
            : MessagesCopy.memberJoined(displayName)
        var members = SampleData.circleBuddies
            .filter { $0.circleName == circle.name }
            .map(\.profile.nickname)
        if !displayName.isEmpty,
           !members.contains(where: { $0.caseInsensitiveCompare(displayName) == .orderedSame }) {
            members.insert(displayName, at: 0)
        }
        let conversation = ChatConversation(
            id: id,
            title: circle.name,
            subtitle: MessagesCopy.circleGroupSubtitleLine(
                memberCount: max(members.count, circle.memberCount)
            ),
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .circle,
            relatedCircleID: circle.id,
            lastMessageIsMe: false,
            ownerName: members.first,
            memberNames: members,
            announcement: circle.summary
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [ChatMessage.systemTip(tip, audience: .everyone)]
        storeBootstrapMembers(for: conversation)
        persist()
        return conversation
    }

    /// 退出圈子群：从列表移除本机会话（演示）
    func leaveCircleChat(circleID: InterestCircle.ID, leaverName: String) {
        guard let conversation = conversations.first(where: {
            $0.kind == .circle && $0.relatedCircleID == circleID
        }) else { return }
        let name = leaverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipName = name.isEmpty ? MessagesCopy.memberFallback : name
        appendSystemTip(
            MessagesCopy.memberLeft(tipName),
            audience: .everyone,
            to: conversation.id
        )
        delete(conversation.id)
        onConversationsChanged?()
    }

    func conversation(forCircleID id: InterestCircle.ID) -> ChatConversation? {
        conversations.first { $0.kind == .circle && $0.relatedCircleID == id }
    }

    func conversation(forActivityID id: Activity.ID) -> ChatConversation? {
        conversations.first {
            $0.kind == .activity && $0.relatedActivityID == id
        }
    }

    /// 退出活动群：写入仅群主可见的退群小字；非群主从自己的列表移除会话。
    func leaveGroupChat(
        activityID: Activity.ID,
        leaverName: String,
        currentUserIsOwner: Bool
    ) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activityID
        }) else { return }

        let name = leaverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipName = name.isEmpty ? MessagesCopy.memberFallback : name
        appendSystemTip(
            MessagesCopy.memberLeft(tipName),
            audience: .hostOnly,
            to: conversation.id
        )

        if currentUserIsOwner {
            persist()
            return
        }
        delete(conversation.id)
        onConversationsChanged?()
    }

    /// 活动改期 / 改标题后同步群聊元数据
    func syncGroupMetadata(for activity: Activity) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activity.id
        }) else { return }
        syncGroupMetadata(conversationID: conversation.id, activity: activity)
    }

    /// 主办取消活动：群聊系统通知 + 更新副标题
    func announceActivityCancelled(activity: Activity) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activity.id
        }) else { return }
        guard let index = index(of: conversation.id) else { return }

        let notice = "【活动取消】发起人已取消「\(activity.title)」。"
        appendSystemTip(notice, audience: .everyone, to: conversation.id)
        conversations[index].subtitle = ActivityDetailCopy.hostCancelledNotice
        conversations[index].updatedAt = .now
        persist()
        onConversationsChanged?()
    }
}
