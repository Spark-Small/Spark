//
//  MessagesModel+MessageActions.swift
//  坐标系
//
//  本机消息动作：编辑 / 撤回 / 转发（不接 B5；不伪造对方回执）。
//

import Foundation
import CoordinateModels

extension MessagesModel {
    /// 编辑自己的文本消息（本机；超过窗口则失败）。
    @discardableResult
    func editMessage(
        messageID: ChatMessage.ID,
        in conversationID: ChatConversation.ID,
        newText: String
    ) -> Bool {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard var list = threads[conversationID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return false }
        var message = list[index]
        guard message.isMe,
              !message.isSystem,
              !message.isRecalled,
              message.messageKind == .text,
              Date().timeIntervalSince(message.sentAt) <= MessagingDeliveryPolicy.localEditWindow
        else { return false }

        message.text = trimmed
        message.editedAt = .now
        list[index] = message
        threads[conversationID] = list
        refreshConversationPreview(conversationID)
        persist()
        return true
    }

    /// 撤回自己的消息：本机改为系统小字（不假装对端也同步）。
    @discardableResult
    func unsendMessage(
        messageID: ChatMessage.ID,
        in conversationID: ChatConversation.ID
    ) -> Bool {
        guard var list = threads[conversationID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return false }
        var message = list[index]
        guard message.isMe, !message.isSystem, !message.isRecalled else { return false }
        guard Date().timeIntervalSince(message.sentAt) <= MessagingDeliveryPolicy.localUnsendWindow
        else { return false }

        message.isRecalled = true
        message.isSystem = true
        message.text = MessagesCopy.messageUnsent
        message.messageKind = .text
        message.reaction = nil
        message.isLiked = false
        message.replyToSender = nil
        message.replyToText = nil
        list[index] = message
        threads[conversationID] = list
        refreshConversationPreview(conversationID)
        persist()
        return true
    }

    /// 转发到另一会话（本机复制 payload，新 id）。
    @discardableResult
    func forwardMessage(
        _ message: ChatMessage,
        to conversationID: ChatConversation.ID
    ) -> ChatMessage? {
        guard !message.isSystem, !message.isRecalled else { return nil }
        guard conversations.contains(where: { $0.id == conversationID }) else { return nil }

        let forwarded = ChatMessage(
            id: UUID(),
            sender: "我",
            text: message.text,
            sentAt: .now,
            isMe: true,
            messageKind: message.messageKind,
            mediaLocalName: message.mediaLocalName,
            voiceDuration: message.voiceDuration,
            locationName: message.locationName,
            latitude: message.latitude,
            longitude: message.longitude,
            linkTitle: message.linkTitle,
            linkSubtitle: message.linkSubtitle,
            linkURLString: message.linkURLString,
            cardActivityID: message.cardActivityID,
            transferAmount: nil,
            transferID: nil
        )
        return sendPayload(forwarded, to: conversationID)
    }

    private func refreshConversationPreview(_ conversationID: ChatConversation.ID) {
        guard let index = index(of: conversationID) else { return }
        let list = threads[conversationID] ?? []
        if let last = list.last {
            conversations[index].lastMessage = last.previewText
            conversations[index].lastMessageIsMe = last.isMe
            conversations[index].updatedAt = last.sentAt
        } else {
            conversations[index].lastMessage = ""
            conversations[index].lastMessageIsMe = false
        }
    }
}
