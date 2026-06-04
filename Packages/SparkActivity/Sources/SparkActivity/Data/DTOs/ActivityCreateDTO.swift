// Module: SparkActivity — Create activity API payloads.

import Foundation

struct CreateActivityRequestDTO: Encodable, Sendable {
    let title: String
    let description: String
    let locationName: String
    let startsAt: String
    let capacity: Int?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case locationName = "location_name"
        case startsAt = "starts_at"
        case capacity
    }
}
