// Module: SparkActivity — Capacity and RSVP eligibility for registrants.

import Foundation

enum ActivityRegistrationRules {
    static func isAtCapacity(attendeeCount: Int, capacity: Int?) -> Bool {
        guard let capacity, capacity > 0 else { return false }
        return attendeeCount >= capacity
    }

    /// `going` is blocked when full unless the user already has a spot.
    static func canSelectGoing(
        attendeeCount: Int,
        capacity: Int?,
        rsvpStatus: ActivityRSVPStatus,
        lifecycleStatus: ActivityLifecycleStatus
    ) -> Bool {
        guard !lifecycleStatus.blocksRegistration else { return false }
        if rsvpStatus == .going || rsvpStatus == .host { return true }
        return !isAtCapacity(attendeeCount: attendeeCount, capacity: capacity)
    }

    static func canChangeRSVP(
        rsvpStatus: ActivityRSVPStatus,
        lifecycleStatus: ActivityLifecycleStatus
    ) -> Bool {
        rsvpStatus != .host && !lifecycleStatus.blocksRegistration
    }

    static func registrationBlockedMessage(
        lifecycleStatus: ActivityLifecycleStatus,
        isAtCapacity: Bool,
        rsvpStatus: ActivityRSVPStatus
    ) -> String? {
        if lifecycleStatus == .cancelled {
            return String(
                localized: "activity.registration.blocked.cancelled",
                defaultValue: "活动已取消，无法报名。",
                comment: "Registration blocked"
            )
        }
        if lifecycleStatus == .ended {
            return String(
                localized: "activity.registration.blocked.ended",
                defaultValue: "活动已结束。",
                comment: "Registration blocked"
            )
        }
        if isAtCapacity, rsvpStatus != .going, rsvpStatus != .maybe, rsvpStatus != .host, rsvpStatus != .waitlisted {
            return String(
                localized: "activity.registration.blocked.full",
                defaultValue: "名额已满，可加入候补或选择「也许」。",
                comment: "Registration blocked"
            )
        }
        return nil
    }

    static func canJoinWaitlist(
        attendeeCount: Int,
        capacity: Int?,
        rsvpStatus: ActivityRSVPStatus,
        lifecycleStatus: ActivityLifecycleStatus
    ) -> Bool {
        guard !lifecycleStatus.blocksRegistration else { return false }
        guard rsvpStatus == .invited else { return false }
        return isAtCapacity(attendeeCount: attendeeCount, capacity: capacity)
    }
}
