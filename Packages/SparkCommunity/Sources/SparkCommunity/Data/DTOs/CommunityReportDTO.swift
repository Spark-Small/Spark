// Module: SparkCommunity — Report post request/response DTOs.

import Foundation

struct ReportCommunityPostRequestDTO: Encodable, Sendable {
    let reason: String
    let detail: String?
}

struct ReportCommunityPostResponseDTO: Decodable, Sendable {
    let reportID: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case reportID = "report_id"
        case status
    }
}
