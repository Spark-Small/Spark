// Module: SparkCommunity — Create recap post API payload.

import Foundation

struct CreateCommunityRecapRequestDTO: Encodable, Sendable {
    let title: String
    let body: String
    let kind: String
    let activityID: String
    let imageURL: String?

    enum CodingKeys: String, CodingKey {
        case title
        case body
        case kind
        case activityID = "activity_id"
        case imageURL = "image_url"
    }
}
