// Module: SparkMessages — Inbox list API payloads.

import Foundation

struct MessageThreadsResponseDTO: Decodable, Sendable {
    let threads: [MessageThreadDTO]
}

struct MessageThreadDTO: Decodable, Sendable {
    let id: String
    let peerDisplayName: String
    let lastMessagePreview: String
    let lastActivityAt: String
    let unreadCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case peerDisplayName = "peer_display_name"
        case lastMessagePreview = "last_message_preview"
        case lastActivityAt = "last_activity_at"
        case unreadCount = "unread_count"
    }
}

struct ThreadMessagesResponseDTO: Decodable, Sendable {
    let messages: [ChatMessageDTO]
}

struct ChatMessageDTO: Decodable, Sendable {
    let id: String
    let threadId: String
    let body: String
    let sentAt: String
    let isFromCurrentUser: Bool
    let kind: String?
    let activityID: String?
    let system: MessagesSystemPayloadDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case body
        case sentAt = "sent_at"
        case isFromCurrentUser = "is_from_current_user"
        case kind
        case activityID = "activity_id"
        case system
    }
}

struct MessagesSystemPayloadDTO: Decodable, Sendable {
    let typeLabel: String
    let title: String
    let body: String
    let ctaTitle: String?
    let ctaActivityID: String?

    enum CodingKeys: String, CodingKey {
        case typeLabel = "type_label"
        case title, body
        case ctaTitle = "cta_title"
        case ctaActivityID = "cta_activity_id"
    }
}

struct SendMessageRequestDTO: Encodable, Sendable {
    let body: String
    let kind: String?

    init(body: String, kind: String? = nil) {
        self.body = body
        self.kind = kind
    }
}
