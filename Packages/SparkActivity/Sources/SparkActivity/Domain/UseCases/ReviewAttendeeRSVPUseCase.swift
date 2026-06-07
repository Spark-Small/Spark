// Module: SparkActivity — Host approve or deny attendee RSVP.

import Foundation

struct ReviewAttendeeRSVPUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, attendeeID: String, approve: Bool) async throws -> ActivityDetail {
        try await repository.reviewAttendeeRSVP(activityID: activityID, attendeeID: attendeeID, approve: approve)
    }
}
