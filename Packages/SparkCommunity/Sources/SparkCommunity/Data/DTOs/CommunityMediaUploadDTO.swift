// Module: SparkCommunity — Staging media upload API payloads.

import Foundation

struct StageCommunityMediaRequestDTO: Encodable, Sendable {
    let kind: String
    let contentSHA256: String
    let contentType: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case contentSHA256 = "content_sha256"
        case contentType = "content_type"
    }
}

struct StageCommunityMediaResponseDTO: Decodable, Sendable {
    let id: String
    let url: String
    let kind: String
    let posterURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case kind
        case posterURL = "poster_url"
    }
}

struct CommunityPostMediaRequestDTO: Encodable, Sendable {
    let id: String?
    let url: String
    let kind: String
    let posterURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case kind
        case posterURL = "poster_url"
    }
}
