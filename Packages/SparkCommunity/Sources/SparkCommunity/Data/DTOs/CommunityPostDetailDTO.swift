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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case body
        case authorDisplayName = "author_display_name"
        case replyCount = "reply_count"
    }
}
