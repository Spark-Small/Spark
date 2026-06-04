// Module: SparkActivity — Who is going (detail preview for registrants).

import Foundation

public struct ActivityAttendee: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let displayName: String
    public let isHost: Bool
    /// Set on host roster payloads (`attendees[].rsvp_status`).
    public let rsvpStatus: ActivityRSVPStatus?
    /// Backend `attendees[].verified` (e.g. real-name verified).
    public let isVerified: Bool

    public init(
        id: String,
        displayName: String,
        isHost: Bool = false,
        rsvpStatus: ActivityRSVPStatus? = nil,
        isVerified: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.isHost = isHost
        self.rsvpStatus = rsvpStatus
        self.isVerified = isVerified
    }
}
