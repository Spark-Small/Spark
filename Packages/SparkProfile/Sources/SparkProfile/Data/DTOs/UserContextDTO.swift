// Module: SparkProfile — GET /v1/users/{id}/context wire types.

import Foundation

struct UserContextResponseDTO: Decodable, Sendable {
    let context: UserContextDTO
}

struct UserContextDTO: Decodable, Sendable {
    let userID: String
    let displayName: String
    let avatarURL: String?
    let bio: String?
    let trustScore: Int?
    let hasLivenessVerification: Bool?
    let relationshipStatus: String?
    let sharedActivities: [SharedActivitySummaryDTO]?
    let timeline: [UserContextTimelineDTO]?

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case displayName = "display_name"
        case avatarURL = "avatar_url"
        case bio
        case trustScore = "trust_score"
        case hasLivenessVerification = "has_liveness_verification"
        case relationshipStatus = "relationship_status"
        case sharedActivities = "shared_activities"
        case timeline
    }
}

struct SharedActivitySummaryDTO: Decodable, Sendable {
    let id: String
    let title: String
}

struct UserContextTimelineDTO: Decodable, Sendable {
    let id: String
    let title: String
    let detail: String?
}

enum UserContextDTOMapper {
    static func context(from dto: UserContextDTO) -> UserContext {
        UserContext(
            userID: dto.userID,
            displayName: dto.displayName,
            avatarURL: dto.avatarURL.flatMap(URL.init(string:)),
            bio: dto.bio ?? "",
            trustScore: dto.trustScore,
            hasLivenessVerification: dto.hasLivenessVerification ?? false,
            relationshipStatus: dto.relationshipStatus,
            sharedActivities: (dto.sharedActivities ?? []).map {
                SharedActivitySummary(id: $0.id, title: $0.title)
            },
            timeline: (dto.timeline ?? []).map {
                UserContextTimelineEntry(id: $0.id, title: $0.title, detail: $0.detail)
            }
        )
    }
}
