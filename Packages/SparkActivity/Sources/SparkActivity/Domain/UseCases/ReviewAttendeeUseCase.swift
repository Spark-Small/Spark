// Module: SparkActivity — Host approves or rejects a pending attendee.

import Foundation

struct ReviewAttendeeUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(
        activityID: String,
        attendeeID: String,
        decision: AttendeeReviewDecision
    ) async throws -> ActivityDetail {
        try await repository.reviewAttendee(
            activityID: activityID,
            attendeeID: attendeeID,
            decision: decision
        )
    }
}
