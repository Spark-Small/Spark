// Module: SparkBuddy — Browse chip filter (includes "all").

import Foundation

public enum BuddyBillingFilter: String, CaseIterable, Identifiable, Sendable, Equatable {
    case all
    case hourly
    case daily
    case perProject

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "buddy.filter.all", defaultValue: "全部", comment: "All billing filter")
        case .hourly:
            BuddyBillingKind.hourly.localizedTitle
        case .daily:
            BuddyBillingKind.daily.localizedTitle
        case .perProject:
            BuddyBillingKind.perProject.localizedTitle
        }
    }

    public var apiBillingValue: String? {
        switch self {
        case .all:
            nil
        case .hourly:
            BuddyBillingKind.hourly.apiValue
        case .daily:
            BuddyBillingKind.daily.apiValue
        case .perProject:
            BuddyBillingKind.perProject.apiValue
        }
    }
}
