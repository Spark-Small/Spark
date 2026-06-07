// Module: SparkTrust — Trust profile wire format.

import Foundation

struct TrustProfileResponseDTO: Decodable, Sendable {
    let trustScore: Int
    let completedLevels: [String]
    let activityAttendanceCount: Int?

    enum CodingKeys: String, CodingKey {
        case trustScore = "trust_score"
        case completedLevels = "completed_levels"
        case activityAttendanceCount = "activity_attendance_count"
    }
}

enum TrustDTOMapper {
    static func profile(from dto: TrustProfileResponseDTO) -> TrustProfile {
        let levels = Set(
            dto.completedLevels.compactMap { TrustLevel(rawValue: $0) }
        )
        return TrustProfile(
            totalScore: dto.trustScore,
            completedLevels: levels,
            activityAttendanceCount: dto.activityAttendanceCount ?? 0
        )
    }
}
