// Module: SparkCommunity — Post like API payloads.

import Foundation

struct SetCommunityPostLikeRequestDTO: Encodable, Sendable {
    let liked: Bool
}

struct CommunityPostLikeResponseDTO: Decodable, Sendable {
    let liked: Bool
    let likeCount: Int

    enum CodingKeys: String, CodingKey {
        case liked
        case likeCount = "like_count"
    }
}
