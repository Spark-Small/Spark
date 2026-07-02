// Module: SparkActivity — Editorial stage badge for browse/inbox cards.

import SwiftUI

/// Single prioritized stage label for list-card hero badges (App Store Today–style).
enum ActivityListStageStatus: Equatable, Sendable {
    case registrationOpen
    case full
    case lifecycle(ActivityLifecycleStatus)
    case rsvp(ActivityRSVPStatus)

    var label: String {
        switch self {
        case .registrationOpen:
            String(
                localized: "activity.stage.registrationOpen",
                defaultValue: "报名中",
                comment: "Activity open for registration"
            )
        case .full:
            String(localized: "activity.badge.full", defaultValue: "已满", comment: "List badge")
        case .lifecycle(let status):
            status.localizedLabel
        case .rsvp(let status):
            status.localizedLabel
        }
    }

    /// Solid editorial tint on cover photos (system semantic colors — not glass).
    var accentColor: Color {
        switch self {
        case .registrationOpen:
            .blue
        case .full:
            .red
        case .lifecycle(let status):
            switch status {
            case .scheduled:
                .blue
            case .cancelled:
                .red
            case .ended:
                .gray
            }
        case .rsvp(let status):
            switch status {
            case .host:
                .indigo
            case .going:
                .green
            case .maybe:
                .teal
            case .waitlisted:
                .orange
            case .invited, .declined:
                .blue
            }
        }
    }
}

extension ActivityItem {
    /// Highest-priority stage for the hero corner badge.
    var listStageStatus: ActivityListStageStatus? {
        if lifecycleStatus != .scheduled {
            return .lifecycle(lifecycleStatus)
        }

        switch rsvpStatus {
        case .host:
            return .rsvp(.host)
        case .going:
            return .rsvp(.going)
        case .maybe:
            return .rsvp(.maybe)
        case .waitlisted:
            return .rsvp(.waitlisted)
        case .invited, .declined:
            return isAtCapacity ? .full : .registrationOpen
        }
    }
}
