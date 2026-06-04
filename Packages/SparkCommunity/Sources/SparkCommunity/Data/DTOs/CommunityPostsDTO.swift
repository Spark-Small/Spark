// Module: SparkCommunity — Community posts API payloads.

import Foundation

struct CommunityPostsResponseDTO: Decodable, Sendable {
    let posts: [CommunityPostDTO]
}

struct CommunityPostDTO: Decodable, Sendable {
    let id: String
    let title: String
    let excerpt: String
    let authorDisplayName: String
    let replyCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case excerpt
        case authorDisplayName = "author_display_name"
        case replyCount = "reply_count"
    }
}
