//
//  MessagesModel+RichPayloads.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    // MARK: - Rich payloads / group / social

    /// View 经 Model 落盘聊天图，再发消息（勿在 View 直连磁盘）。
    @discardableResult
    func sendImageJPEG(_ data: Data, to id: ChatConversation.ID) -> ChatMessage? {
        guard let name = LocalMediaLibrary.saveJPEG(data) else { return nil }
        return sendImage(localName: name, to: id)
    }

    func sendImage(localName: String, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: MessagesCopy.imagePlaceholder, sentAt: .now, isMe: true,
                messageKind: .image, mediaLocalName: localName
            ),
            to: id
        )
    }

    func sendVoice(duration: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: "[语音]", sentAt: .now, isMe: true,
                messageKind: .voice, voiceDuration: duration
            ),
            to: id
        )
    }

    func sendLocation(name: String, latitude: Double, longitude: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: name, sentAt: .now, isMe: true,
                messageKind: .location, locationName: name, latitude: latitude, longitude: longitude
            ),
            to: id
        )
    }

    func sendActivityCard(_ activity: Activity, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: activity.title, sentAt: .now, isMe: true,
                messageKind: .activity,
                linkSubtitle: "\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)",
                cardActivityID: activity.id
            ),
            to: id
        )
    }

    func sendTransfer(amount: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: MessagesCopy.transferTitle, sentAt: .now, isMe: true,
                messageKind: .transfer, transferAmount: amount
            ),
            to: id
        )
    }

    func sendSticker(_ emoji: String, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: emoji, sentAt: .now, isMe: true,
                messageKind: .sticker
            ),
            to: id
        )
    }

    func setReaction(_ emoji: String?, on messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard var list = threads[conversationID],
              let idx = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[idx].reaction = emoji
        if emoji == "❤️" { list[idx].isLiked = true }
        threads[conversationID] = list
        persist()
    }
}
