// Module: SparkMessages — Unified inbox API DTOs.

import Foundation

struct MessagesInboxResponseDTO: Decodable, Sendable {
    let actionItems: [ActionItemDTO]
    let unmessagedMatches: [MatchPreviewDTO]
    let dmConversations: [ConversationPreviewDTO]
    let groupConversations: [ConversationPreviewDTO]

    enum CodingKeys: String, CodingKey {
        case actionItems = "action_items"
        case unmessagedMatches = "unmessaged_matches"
        case dmConversations = "dm_conversations"
        case groupConversations = "group_conversations"
    }
}

struct ActionItemDTO: Decodable, Sendable {
    let id: String
    let type: String
    let priority: Int
    let createdAt: String
    let invite: ActivityInviteDTO?
    let change: ActivityChangeDTO?
    let activity: InboxActivitySummaryDTO?

    enum CodingKeys: String, CodingKey {
        case id, type, priority
        case createdAt = "created_at"
        case invite, change, activity
    }
}

struct ActivityInviteDTO: Decodable, Sendable {
    let id: String
    let activity: InboxActivitySummaryDTO
    let inviter: InboxUserProfileDTO
}

struct ActivityChangeDTO: Decodable, Sendable {
    let id: String
    let kind: String
    let activity: InboxActivitySummaryDTO
    let hostName: String
    let previousScheduleLine: String

    enum CodingKeys: String, CodingKey {
        case id, kind, activity
        case hostName = "host_name"
        case previousScheduleLine = "previous_schedule_line"
    }
}

struct MatchPreviewDTO: Decodable, Sendable {
    let id: String
    let user: InboxUserProfileDTO
    let matchedAt: String
    let threadID: String?

    enum CodingKeys: String, CodingKey {
        case id, user
        case matchedAt = "matched_at"
        case threadID = "thread_id"
    }
}

struct ConversationPreviewDTO: Decodable, Sendable {
    let id: String
    let kind: String
    let displayName: String
    let lastMessagePreview: String
    let lastMessageAt: String
    let unreadCount: Int
    let dmPartner: InboxUserProfileDTO?
    let isPartnerOnline: Bool?
    let activity: InboxActivitySummaryDTO?
    let memberCount: Int?
    let isArchived: Bool?

    enum CodingKeys: String, CodingKey {
        case id, kind
        case displayName = "display_name"
        case lastMessagePreview = "last_message_preview"
        case lastMessageAt = "last_message_at"
        case unreadCount = "unread_count"
        case dmPartner = "dm_partner"
        case isPartnerOnline = "is_partner_online"
        case activity
        case memberCount = "member_count"
        case isArchived = "is_archived"
    }
}

struct InboxUserProfileDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let firstName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case firstName = "first_name"
    }
}

struct InboxActivitySummaryDTO: Decodable, Sendable {
    let id: String
    let title: String
    let coverURL: String?
    let startsAt: String
    let attendeeCount: Int
    let lifecycle: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case coverURL = "cover_url"
        case startsAt = "starts_at"
        case attendeeCount = "attendee_count"
        case lifecycle
    }
}

struct ConversationContextResponseDTO: Decodable, Sendable {
    let sharedActivities: [InboxActivitySummaryDTO]
    let relationshipStatus: String

    enum CodingKeys: String, CodingKey {
        case sharedActivities = "shared_activities"
        case relationshipStatus = "relationship_status"
    }
}
