// Module: SparkCommunity — Community post detail API payload.

import Foundation

struct CommunityPostDetailResponseDTO: Decodable, Sendable {
    let post: CommunityPostDetailDTO
}

struct CommunityPostDetailDTO: Decodable, Sendable {
    let id: String
    let title: String
    let body: String
    let authorDisplayName: String
    let authorUserID: String?
    let replyCount: Int
    let replies: [CommunityPostReplyDTO]?
    let linkedActivity: LinkedActivityDTO?
    let media: [CommunityPostMediaDTO]?
    let tags: [String]?
    let kind: String?
    let likeCount: Int?
    let viewerHasLiked: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case authorDisplayName = "author_display_name"
        case authorUserID = "author_user_id"
        case replyCount = "reply_count"
        case replies
        case linkedActivity = "linked_activity"
        case media
        case tags
        case kind
        case likeCount = "like_count"
        case viewerHasLiked = "viewer_has_liked"
    }
}

struct CommunityPostReplyDTO: Decodable, Sendable {
    let id: String
    let body: String
    let authorDisplayName: String
    let createdAt: String?
    let relationshipToViewer: String?

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case authorDisplayName = "author_display_name"
        case createdAt = "created_at"
        case relationshipToViewer = "relationship_to_viewer"
    }
}

struct CreateCommunityReplyRequestDTO: Encodable, Sendable {
    let body: String
}

struct CreateCommunityReplyResponseDTO: Decodable, Sendable {
    let reply: CommunityPostReplyDTO
}
