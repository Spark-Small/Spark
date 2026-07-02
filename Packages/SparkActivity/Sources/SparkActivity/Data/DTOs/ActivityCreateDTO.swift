// Module: SparkActivity — Create activity API payloads.

import Foundation

struct CreateActivityRequestDTO: Encodable, Sendable {
    let title: String
    let description: String
    let locationName: String
    let startsAt: String
    let capacity: Int?
    let coverURL: String?
    let coverPosterURL: String?
    let coverIsVideo: Bool?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case locationName = "location_name"
        case startsAt = "starts_at"
        case capacity
        case coverURL = "cover_url"
        case coverPosterURL = "cover_poster_url"
        case coverIsVideo = "cover_is_video"
    }
}
