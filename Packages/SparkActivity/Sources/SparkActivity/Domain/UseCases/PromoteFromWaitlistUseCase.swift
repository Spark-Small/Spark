// Module: SparkActivity — Host promotes a waitlisted attendee.

import Foundation

struct PromoteFromWaitlistUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        try await repository.promoteFromWaitlist(activityID: activityID, attendeeID: attendeeID)
    }
}
