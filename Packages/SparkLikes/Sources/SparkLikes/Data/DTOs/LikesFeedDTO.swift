// Module: SparkLikes — Wire types for discover feed.

import Foundation

struct LikesFeedResponseDTO: Decodable, Sendable {
    let items: [DiscoverCardDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

struct LikesInboundResponseDTO: Decodable, Sendable {
    let items: [InboundLikeItemDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

struct InboundLikeItemDTO: Decodable, Sendable {
    let userID: String
    let likedAt: String?
    let isVisible: Bool?
    let card: DiscoverCardDTO

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case likedAt = "liked_at"
        case isVisible = "is_visible"
        case card
    }
}

struct AvatarUploadURLResponseDTO: Decodable, Sendable {
    let uploadURL: String?
    let avatarURL: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case uploadURL = "upload_url"
        case avatarURL = "avatar_url"
        case expiresAt = "expires_at"
    }
}

struct AvatarUploadURLRequestDTO: Encodable, Sendable {
    let contentType: String

    enum CodingKeys: String, CodingKey {
        case contentType = "content_type"
    }
}

struct DiscoverCardDTO: Decodable, Sendable {
    let userID: String
    let displayName: String
    let bio: String?
    let gender: String?
    let media: DiscoverMediaDTO
    let mediaItems: [DiscoverMediaDTO]?
    let interestTags: [String]?
    let coarseLocation: String?
    let sharedActivity: SharedActivityDTO?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case bio
        case gender
        case media
        case mediaItems = "media_items"
        case interestTags = "interest_tags"
        case coarseLocation = "coarse_location"
        case sharedActivity = "shared_activity"
    }
}

struct SharedActivityDTO: Decodable, Sendable {
    let activityID: String
    let title: String

    enum CodingKeys: String, CodingKey {
        case activityID = "activity_id"
        case title
    }
}

struct DiscoverMediaDTO: Decodable, Sendable {
    let kind: String
    let url: String
    let posterURL: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case url
        case posterURL = "poster_url"
    }
}

struct LikesViewerProfileDTO: Decodable, Sendable {
    let displayName: String
    let hasPhoto: Bool
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case hasPhoto = "has_photo"
        case avatarURL = "avatar_url"
    }
}

struct LikesViewerProfileRequestDTO: Encodable, Sendable {
    let displayName: String
    let hasPhoto: Bool
    let avatarURL: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
        case hasPhoto = "has_photo"
        case avatarURL = "avatar_url"
    }
}

struct LikesRewindResponseDTO: Decodable, Sendable {
    let card: DiscoverCardDTO?
}

struct LikeActionResponseDTO: Decodable, Sendable {
    let outcome: String
    let threadID: String?

    enum CodingKeys: String, CodingKey {
        case outcome
        case threadID = "thread_id"
    }
}

struct FriendRequestResponseDTO: Decodable, Sendable {
    let outcome: String
}

struct LikesReportResponseDTO: Decodable, Sendable {
    let reportID: String

    enum CodingKeys: String, CodingKey {
        case reportID = "report_id"
    }
}

struct LikesReportRequestDTO: Encodable, Sendable {
    let reason: String
    let detail: String?
}
