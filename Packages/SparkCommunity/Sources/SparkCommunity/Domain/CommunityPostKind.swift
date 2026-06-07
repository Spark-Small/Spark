// Module: SparkCommunity — Post classification for feed filters.

import Foundation

public enum CommunityPostKind: String, Sendable, Equatable, Hashable, Codable {
    case discussion
    case activityRecap = "activity_recap"
}
