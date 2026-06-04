// Module: SparkActivity — Host-facing RSVP breakdown.

import Foundation

public struct ActivitySignupCounts: Sendable, Equatable {
    public let going: Int
    public let maybe: Int
    public let declined: Int
    public let waitlisted: Int

    public init(going: Int = 0, maybe: Int = 0, declined: Int = 0, waitlisted: Int = 0) {
        self.going = going
        self.maybe = maybe
        self.declined = declined
        self.waitlisted = waitlisted
    }

    public var localizedSummary: String {
        if waitlisted > 0 {
            let format = String(
                localized: "activity.host.signups.withWaitlist.format",
                defaultValue: "参加 %lld · 也许 %lld · 不参加 %lld · 候补 %lld",
                comment: "Host signup summary with waitlist"
            )
            return String(format: format, locale: .current, going, maybe, declined, waitlisted)
        }
        let format = String(
            localized: "activity.host.signups.format",
            defaultValue: "参加 %lld · 也许 %lld · 不参加 %lld",
            comment: "Host signup summary; three %lld counts"
        )
        return String(format: format, locale: .current, going, maybe, declined)
    }
}
