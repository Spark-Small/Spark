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

    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case body
        case sentAt = "sent_at"
        case isFromCurrentUser = "is_from_current_user"
    }
}

struct SendMessageRequestDTO: Encodable, Sendable {
    let body: String
}
