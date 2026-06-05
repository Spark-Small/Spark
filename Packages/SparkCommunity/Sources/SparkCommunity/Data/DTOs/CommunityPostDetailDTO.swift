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
    let replyCount: Int
    let replies: [CommunityPostReplyDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case authorDisplayName = "author_display_name"
        case replyCount = "reply_count"
        case replies
    }
}

struct CommunityPostReplyDTO: Decodable, Sendable {
    let id: String
    let body: String
    let authorDisplayName: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case body
        case authorDisplayName = "author_display_name"
        case createdAt = "created_at"
    }
}

struct CreateCommunityReplyRequestDTO: Encodable, Sendable {
    let body: String
}

struct CreateCommunityReplyResponseDTO: Decodable, Sendable {
    let reply: CommunityPostReplyDTO
}
