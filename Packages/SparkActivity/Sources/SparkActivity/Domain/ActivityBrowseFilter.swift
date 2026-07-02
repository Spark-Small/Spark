// Module: SparkActivity — Discover browse chips (time + category, single selection).

import Foundation

/// Single-select chip for Activity discover browse (`GET /v1/activities/browse` query mapping).
public enum ActivityBrowseFilter: String, CaseIterable, Identifiable, Sendable, Equatable {
    case all
    case today
    case tomorrow
    case thisWeek
    case thisMonth
    case events
    case social
    case outdoor

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "activity.browse.filter.all", defaultValue: "全部", comment: "All browse filter")
        case .today:
            String(localized: "activity.browse.filter.today", defaultValue: "今天", comment: "Today browse filter")
        case .tomorrow:
            String(localized: "activity.browse.filter.tomorrow", defaultValue: "明天", comment: "Tomorrow browse filter")
        case .thisWeek:
            String(localized: "activity.browse.filter.thisWeek", defaultValue: "本周", comment: "This week browse filter")
        case .thisMonth:
            String(localized: "activity.browse.filter.thisMonth", defaultValue: "本月", comment: "This month browse filter")
        case .events:
            String(localized: "activity.category.event", defaultValue: "活动", comment: "Activity category")
        case .social:
            String(localized: "activity.category.social", defaultValue: "社交", comment: "Social category")
        case .outdoor:
            String(localized: "activity.category.outdoor", defaultValue: "户外", comment: "Outdoor category")
        }
    }

    public var category: String? {
        apiCategoryValue
    }

    /// Stable catalog label for `GET /v1/activities/browse?category=` (API exact match).
    public var apiCategoryValue: String? {
        switch self {
        case .events:
            "活动"
        case .social:
            "社交"
        case .outdoor:
            "户外"
        case .all, .today, .tomorrow, .thisWeek, .thisMonth:
            nil
        }
    }

    public var startsAfter: Date? {
        switch self {
        case .all, .events, .social, .outdoor:
            return nil
        case .today:
            return Self.dayStart(offset: 0)
        case .tomorrow:
            return Self.dayStart(offset: 1)
        case .thisWeek:
            return Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start
        case .thisMonth:
            return Calendar.current.dateInterval(of: .month, for: Date())?.start
        }
    }

    public var startsBefore: Date? {
        switch self {
        case .all, .events, .social, .outdoor:
            return nil
        case .today:
            return Self.dayStart(offset: 1)
        case .tomorrow:
            return Self.dayStart(offset: 2)
        case .thisWeek:
            return Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.end
        case .thisMonth:
            return Calendar.current.dateInterval(of: .month, for: Date())?.end
        }
    }

    private static func dayStart(offset: Int) -> Date? {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: offset, to: startOfToday)
    }
}
