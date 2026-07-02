// Module: SparkBuddy — Listing billing unit (hour / day / project).

import Foundation

/// How a companion listing charges for paid play or offline meetups.
public enum BuddyBillingKind: String, Sendable, Equatable, Codable {
    case hourly
    case daily
    case perProject

    public var localizedTitle: String {
        switch self {
        case .hourly:
            String(localized: "buddy.billing.hourly", defaultValue: "按小时", comment: "Hourly billing")
        case .daily:
            String(localized: "buddy.billing.daily", defaultValue: "按天", comment: "Daily billing")
        case .perProject:
            String(localized: "buddy.billing.perProject", defaultValue: "按项目", comment: "Per-project billing")
        }
    }

    public var localizedUnitSuffix: String {
        switch self {
        case .hourly:
            String(localized: "buddy.billing.unit.hour", defaultValue: "/小时", comment: "Per hour price suffix")
        case .daily:
            String(localized: "buddy.billing.unit.day", defaultValue: "/天", comment: "Per day price suffix")
        case .perProject:
            String(localized: "buddy.billing.unit.project", defaultValue: "/项目", comment: "Per project price suffix")
        }
    }

    /// Stable value for `GET /v1/buddies?billing=`.
    public var apiValue: String {
        switch self {
        case .hourly: "hourly"
        case .daily: "daily"
        case .perProject: "per_project"
        }
    }

    public init?(apiValue: String) {
        switch apiValue {
        case "hourly": self = .hourly
        case "daily": self = .daily
        case "per_project": self = .perProject
        default: return nil
        }
    }
}
