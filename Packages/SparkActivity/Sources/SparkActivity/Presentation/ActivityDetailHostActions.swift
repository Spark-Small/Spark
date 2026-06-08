// Module: SparkActivity — Host attendee review / cohost mutations.

import Foundation

@MainActor
enum ActivityDetailHostActions {
    static func reviewAttendee(
        activityID: String,
        attendeeID: String,
        decision: AttendeeReviewDecision,
        reviewAttendee: ReviewAttendeeUseCase
    ) async throws -> ActivityDetail {
        try await reviewAttendee(activityID: activityID, attendeeID: attendeeID, decision: decision)
    }

    static func assignCohost(
        activityID: String,
        attendeeID: String,
        assignCohost: AssignCohostUseCase
    ) async throws -> ActivityDetail {
        try await assignCohost(activityID: activityID, attendeeID: attendeeID)
    }
}
