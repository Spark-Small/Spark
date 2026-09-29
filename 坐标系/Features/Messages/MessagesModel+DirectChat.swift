//
//  MessagesModel+DirectChat.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    /// 发起好友聊天。已存在时：`deliverGreeting == true` 会把问候作为新消息发出；
    /// `deliverGreeting == false` 时仅打开空会话，不自动发消息。
    @discardableResult
    func startChat(
        with nickname: String,
        greeting: String = MessagesCopy.defaultGreeting,
        deliverGreeting: Bool = false
    ) -> ChatConversation? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGreeting = greeting.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if deliverGreeting, !trimmedGreeting.isEmpty {
                let last = threads[existing.id]?.last
                let duplicate = last?.isMe == true && last?.text == trimmedGreeting
                if !duplicate {
                    send(text: trimmedGreeting, to: existing.id)
                }
            }
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let deliversSeed = deliverGreeting
        let seed = trimmedGreeting.isEmpty ? MessagesCopy.defaultGreeting : trimmedGreeting
        let conversation = ChatConversation(
            id: id,
            title: name,
            subtitle: MessagesCopy.friendSubtitle,
            lastMessage: deliversSeed ? seed : MessagesCopy.emptyThreadTitle,
            updatedAt: .now,
            unreadCount: 0,
            kind: .direct,
            lastMessageIsMe: deliversSeed
        )
        conversations.insert(conversation, at: 0)
        if deliversSeed {
            threads[id] = [
                ChatMessage(id: UUID(), sender: "我", text: seed, sentAt: .now, isMe: true)
            ]
        } else {
            threads[id] = []
        }
        persist()
        onConversationsChanged?()
        return conversation
    }

    /// 从最新消息向前统计连续发出的消息数（跳过系统提示）。
    func trailingOutboundCount(for conversationID: ChatConversation.ID) -> Int {
        guard let thread = threads[conversationID] else { return 0 }
        var count = 0
        for message in thread.reversed() {
            if message.isSystem { continue }
            if message.isMe {
                count += 1
            } else {
                break
            }
        }
        return count
    }

    /// 选好友发起：1 人私聊，2 人及以上建群（含自己为多人）。
    @discardableResult
    func startChat(withMembers nicknames: [String], ownerName: String) -> ChatConversation? {
        let owner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let members: [String] = nicknames.compactMap { raw in
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            if !owner.isEmpty, name.caseInsensitiveCompare(owner) == .orderedSame { return nil }
            let key = name.lowercased()
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            return name
        }
        guard !members.isEmpty else { return nil }

        if members.count == 1 {
            return startChat(with: members[0], deliverGreeting: false)
        }

        let memberKey = Set(members.map { $0.lowercased() })
        if let existing = conversations.first(where: { conversation in
            guard conversation.kind == .group else { return false }
            let peers = conversation.memberNames.filter {
                owner.isEmpty || $0.caseInsensitiveCompare(owner) != .orderedSame
            }
            return Set(peers.map { $0.lowercased() }) == memberKey
        }) {
            return existing
        }

        let id = UUID()
        let tip = MessagesCopy.groupCreated
        var allMembers = members
        if !owner.isEmpty {
            allMembers.insert(owner, at: 0)
        }
        let conversation = ChatConversation(
            id: id,
            title: MessagesCopy.peerGroupTitle(members),
            subtitle: MessagesCopy.groupSubtitle,
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .group,
            lastMessageIsMe: false,
            ownerName: owner.isEmpty ? nil : owner,
            memberNames: allMembers
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [ChatMessage.systemTip(tip, audience: .everyone)]
        storeBootstrapMembers(for: conversation)
        persist()
        onConversationsChanged?()
        return conversation
    }
}
