// Module: SparkMessages — Direct message thread DTOs.

import Foundation

struct EnsureDirectMessageThreadRequestDTO: Encodable, Sendable {
    let peerUserID: String
    let peerDisplayName: String

    enum CodingKeys: String, CodingKey {
        case peerUserID = "peer_user_id"
        case peerDisplayName = "peer_display_name"
    }
}

struct DirectMessageThreadResponseDTO: Decodable, Sendable {
    let threadID: String

    enum CodingKeys: String, CodingKey {
        case threadID = "thread_id"
    }
}
