//
//  MessagesModel+ConversationSharing.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels

extension MessagesModel {
    func appendSystemTip(
        _ text: String,
        audience: ChatSystemAudience,
        to id: ChatConversation.ID
    ) {
        guard let index = index(of: id) else { return }
        if let last = threads[id]?.last,
           last.isSystem,
           last.text == text,
           last.systemAudience == audience {
            return
        }
        let tip = ChatMessage.systemTip(text, audience: audience)
        threads[id, default: []].append(tip)
        conversations[index].lastMessage = text
        conversations[index].lastMessageIsMe = false
        conversations[index].updatedAt = tip.sentAt
        persist()
        onConversationsChanged?()
    }

    func syncGroupMetadata(conversationID: ChatConversation.ID, activity: Activity) {
        guard let index = index(of: conversationID) else { return }
        var changed = false
        if conversations[index].title != activity.title {
            conversations[index].title = activity.title
            changed = true
        }
        if conversations[index].eventAt != activity.date {
            conversations[index].eventAt = activity.date
            changed = true
        }
        if conversations[index].relatedActivityID != activity.id {
            conversations[index].relatedActivityID = activity.id
            changed = true
        }
        if conversations[index].ownerName != activity.hostName {
            conversations[index].ownerName = activity.hostName
            changed = true
        }
        let subtitle = MessagesCopy.activityGroupSubtitleLine(eventAt: activity.date)
        if conversations[index].subtitle != subtitle {
            conversations[index].subtitle = subtitle
            changed = true
        }
        if changed { persist() }
    }

    /// 把社区分享发到好友会话
    @discardableResult
    func shareCommunityPost(
        title: String,
        preview: String,
        to nickname: String,
        postID: UUID? = nil
    ) -> ChatConversation? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let text = "【社区分享】\(title)\n\(preview)"
        let card = ChatMessage(
            id: UUID(),
            sender: "我",
            text: title,
            sentAt: .now,
            isMe: true,
            messageKind: .link,
            linkTitle: title,
            linkSubtitle: preview,
            linkURLString: postID.map { "zuobiaoxi://community/\($0.uuidString)" },
            deliveryStatus: MessagingDeliveryPolicy.upgradesLocalSendToDelivered ? .delivered : .sent
        )
        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            _ = sendPayload(card, to: existing.id)
            return existing
        }
        guard let created = startChat(with: name, greeting: text, deliverGreeting: false) else { return nil }
        _ = sendPayload(card, to: created.id)
        return created
    }
}
