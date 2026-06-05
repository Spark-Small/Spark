// Module: SparkCommunity — Tab feed API payloads.

import Foundation

struct CommunityTabFeedResponseDTO: Decodable, Sendable {
    let joinedCommunities: [CommunitySummaryDTO]
    let items: [CommunityFeedItemDTO]
    let allCommunities: [CommunitySummaryDTO]

    enum CodingKeys: String, CodingKey {
        case joinedCommunities = "joined_communities"
        case items
        case allCommunities = "all_communities"
    }
}

struct CommunitySummaryDTO: Decodable, Sendable {
    let id: String
    let name: String
    let coverURL: String?
    let memberCount: Int
    let activityCount: Int
    let hasNewPosts: Bool
    let bio: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coverURL = "cover_url"
        case memberCount = "member_count"
        case activityCount = "activity_count"
        case hasNewPosts = "has_new_posts"
        case bio
    }
}

struct CommunityFeedItemDTO: Decodable, Sendable {
    let type: String
    let post: CommunityFeedPostDTO?
    let people: [DiscoveredPersonDTO]?
}

struct CommunityFeedPostDTO: Decodable, Sendable {
    let id: String
    let authorDisplayName: String
    let authorUserID: String
    let communityName: String
    let content: String
    let imageURL: String?
    let likeCount: Int
    let commentCount: Int
    let tags: [String]?
    let createdAt: String
    let sharedActivityWithViewer: SharedActivityDTO?
    let relationshipToViewer: String?
    let linkedActivity: LinkedActivityDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case authorDisplayName = "author_display_name"
        case authorUserID = "author_user_id"
        case communityName = "community_name"
        case content
        case imageURL = "image_url"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case tags
        case createdAt = "created_at"
        case sharedActivityWithViewer = "shared_activity_with_viewer"
        case relationshipToViewer = "relationship_to_viewer"
        case linkedActivity = "linked_activity"
    }
}

struct SharedActivityDTO: Decodable, Sendable {
    let id: String
    let name: String
}

struct LinkedActivityDTO: Decodable, Sendable {
    let id: String
    let name: String
}

struct DiscoveredPersonDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let sharedTag: String
    let relationship: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case sharedTag = "shared_tag"
        case relationship
    }
}

struct CommunityDetailResponseDTO: Decodable, Sendable {
    let community: CommunityDetailDTO
}

struct CommunityDetailDTO: Decodable, Sendable {
    let id: String
    let name: String
    let coverURL: String?
    let memberCount: Int
    let activityCount: Int
    let hasNewPosts: Bool
    let bio: String?
    let isJoined: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coverURL = "cover_url"
        case memberCount = "member_count"
        case activityCount = "activity_count"
        case hasNewPosts = "has_new_posts"
        case bio
        case isJoined = "is_joined"
    }
}

struct CommunityActivitiesResponseDTO: Decodable, Sendable {
    let activities: [CommunityLinkedActivityDTO]
}

struct CommunityLinkedActivityDTO: Decodable, Sendable {
    let id: String
    let title: String
    let scheduleLine: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case scheduleLine = "schedule_line"
    }
}

struct CommunityMembersResponseDTO: Decodable, Sendable {
    let members: [CommunityMemberDTO]
}

struct CommunityMemberDTO: Decodable, Sendable {
    let id: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let relationshipToViewer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case relationshipToViewer = "relationship_to_viewer"
    }
}
