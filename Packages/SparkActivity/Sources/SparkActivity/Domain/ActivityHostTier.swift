// Module: SparkActivity — Organizer reputation tier from API.

import Foundation

public enum ActivityHostTier: String, Sendable, Hashable, Equatable {
    case standard
    case superOrganizer

    public init(wireValue: String?) {
        switch wireValue?.lowercased() {
        case "super_organizer":
            self = .superOrganizer
        default:
            self = .standard
        }
    }

    public var localizedBadgeLabel: String? {
        switch self {
        case .standard:
            nil
        case .superOrganizer:
            String(
                localized: "activity.host.tier.superOrganizer",
                defaultValue: "Super Organizer",
                comment: "Meetup-style super organizer badge"
            )
        }
    }
}
