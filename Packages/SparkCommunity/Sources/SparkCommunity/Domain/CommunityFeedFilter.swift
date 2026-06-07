// Module: SparkCommunity — Feed segment filters (Nexus W5).

import Foundation

public enum CommunityFeedFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case recaps

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "community.filter.all", defaultValue: "全部", comment: "All posts")
        case .recaps:
            String(localized: "community.filter.recaps", defaultValue: "活动复盘", comment: "Recap posts")
        }
    }
}
