// Module: SparkActivity — Inbox segmented pages (discover vs mine).

import Foundation

enum ActivityInboxSegment: String, CaseIterable, Identifiable, Sendable {
    case discover
    case mine

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .discover:
            String(
                localized: "activity.segment.discover",
                defaultValue: "发现",
                comment: "Public activity browse segment"
            )
        case .mine:
            String(
                localized: "activity.segment.mine",
                defaultValue: "我的行程",
                comment: "Personal activity itinerary segment"
            )
        }
    }
}
