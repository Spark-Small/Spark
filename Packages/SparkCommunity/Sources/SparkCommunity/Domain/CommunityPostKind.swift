// Module: SparkCommunity — Post classification for community feed.

import Foundation

public enum CommunityPostKind: String, Sendable, Equatable, Hashable, Codable {
    case discussion
    case activityRecap = "activity_recap"
}
