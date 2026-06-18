// Module: SparkActivity — Discover segment list vs map toggle.

import Foundation

enum ActivityDiscoverViewMode: String, CaseIterable, Identifiable, Sendable {
    case list
    case map

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .list:
            String(localized: "activity.discover.mode.list", defaultValue: "列表", comment: "Discover list mode")
        case .map:
            String(
                localized: "activity.discover.mode.map",
                defaultValue: "活动地图",
                comment: "Discover public activity map"
            )
        }
    }
}
