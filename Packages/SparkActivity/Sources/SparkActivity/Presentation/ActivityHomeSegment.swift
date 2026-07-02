// Module: SparkActivity — Activity tab top-level segments (discover vs map).

import Foundation

enum ActivityHomeSegment: String, CaseIterable, Identifiable, Sendable {
    case discover
    case map

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .discover:
            String(
                localized: "activity.home.segment.discover",
                defaultValue: "发现",
                comment: "Activity home discover segment"
            )
        case .map:
            String(
                localized: "activity.home.segment.map",
                defaultValue: "地图",
                comment: "Activity home map segment"
            )
        }
    }
}
