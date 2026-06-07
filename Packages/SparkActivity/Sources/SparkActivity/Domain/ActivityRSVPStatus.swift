// Module: SparkActivity — Invitation RSVP state.

import Foundation

/// User's relationship to an activity invite (`rsvp_status` in API).
public enum ActivityRSVPStatus: String, Sendable, Equatable, CaseIterable {
    case invited
    case going
    case maybe
    case declined
    case waitlisted
    case host

    public init?(wireValue: String) {
        let normalized = wireValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.init(rawValue: normalized)
    }

    public var localizedLabel: String {
        switch self {
        case .invited:
            String(localized: "activity.rsvp.invited", defaultValue: "待确认", comment: "RSVP status")
        case .going:
            String(localized: "activity.rsvp.going", defaultValue: "参加", comment: "RSVP status")
        case .maybe:
            String(localized: "activity.rsvp.maybe", defaultValue: "也许", comment: "RSVP status")
        case .declined:
            String(localized: "activity.rsvp.declined", defaultValue: "不参加", comment: "RSVP status")
        case .waitlisted:
            String(localized: "activity.rsvp.waitlisted", defaultValue: "候补", comment: "RSVP status")
        case .host:
            String(localized: "activity.rsvp.host", defaultValue: "主办", comment: "RSVP status")
        }
    }

    /// Statuses the invitee can choose on the detail screen.
    public static let selectableResponses: [ActivityRSVPStatus] = [.going, .maybe, .declined]

    public var canSelectResponse: Bool {
        self == .invited
    }

    /// Meetup-style: group chat unlocks after signup (going / maybe) or for hosts.
    public var hasGroupChatAccess: Bool {
        switch self {
        case .going, .maybe, .host:
            true
        case .invited, .declined, .waitlisted:
            false
        }
    }

    public var isOnWaitlist: Bool {
        self == .waitlisted
    }

    /// Shown on RSVP section when user still needs to sign up.
    public var registrationSectionTitle: String {
        String(localized: "activity.registration.section", defaultValue: "报名", comment: "Registration section")
    }
}
