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

    /// 清空群聊本地消息记录（保留会话）
    func clearChatHistory(in conversationID: ChatConversation.ID) {
        threads[conversationID] = []
        guard let index = index(of: conversationID) else {
            persist()
            return
        }
        conversations[index].lastMessage = MessagesCopy.emptyThreadTitle
        conversations[index].lastMessageIsMe = false
        conversations[index].updatedAt = .now
        conversations[index].unreadCount = 0
        persist()
        onConversationsChanged?()
    }

    func kickMember(_ name: String, from conversationID: ChatConversation.ID) {
        removeMember(name, from: conversationID)
    }

    func addMember(_ name: String, to conversationID: ChatConversation.ID) {
        inviteMembers([name], to: conversationID)
    }
}
