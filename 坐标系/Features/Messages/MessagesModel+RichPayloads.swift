//
//  MessagesModel+RichPayloads.swift
//  坐标系
//
//  富消息：图片 / 语音 / 定位 / 活动卡 / 表情回应。
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    // MARK: - Rich payloads

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

    func sendVoice(duration: Double, localName: String? = nil, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: "[语音]", sentAt: .now, isMe: true,
                messageKind: .voice, mediaLocalName: localName, voiceDuration: duration
            ),
            to: id
        )
    }

    /// Composer 录音完成：临时 m4a → 本机库 → 会话气泡（不上传；B5）。
    func sendRecordedVoice(fileURL: URL, duration: Double, to id: ChatConversation.ID) -> ChatMessage? {
        guard let name = LocalMediaLibrary.importAudio(from: fileURL) else { return nil }
        try? FileManager.default.removeItem(at: fileURL)
        return sendVoice(duration: duration, localName: name, to: id)
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
