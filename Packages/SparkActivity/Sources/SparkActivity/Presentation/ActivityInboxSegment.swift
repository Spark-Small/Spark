// Module: SparkActivity — Inbox segmented pages (list vs map).

import Foundation

enum ActivityInboxSegment: String, CaseIterable, Identifiable, Sendable {
    case activities
    case map

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .activities:
            String(
                localized: "activity.segment.list",
                defaultValue: "活动",
                comment: "Activity inbox list segment"
            )
        case .map:
            String(
                localized: "activity.segment.map",
                defaultValue: "地图",
                comment: "Activity inbox map segment"
            )
        }
    }
}
