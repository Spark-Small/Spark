// Module: SparkActivity — Browse list time filters (Phase 19).

import Foundation

/// Relative window for `GET /v1/activities/browse` date filters.
public enum ActivityBrowseTimeWindow: String, CaseIterable, Sendable, Equatable {
    case all
    case thisWeek
    case thisMonth

    public var startsAfter: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all:
            return nil
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.start
        }
    }

    public var startsBefore: Date? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .all:
            return nil
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.end
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)?.end
        }
    }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "activity.browse.time.all", defaultValue: "全部", comment: "All time")
        case .thisWeek:
            String(localized: "activity.browse.time.week", defaultValue: "本周", comment: "This week")
        case .thisMonth:
            String(localized: "activity.browse.time.month", defaultValue: "本月", comment: "This month")
        }
    }
}
