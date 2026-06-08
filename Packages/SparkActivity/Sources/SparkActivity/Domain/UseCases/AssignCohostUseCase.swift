// Module: SparkActivity — Host assigns co-host to a going attendee.

import Foundation

struct AssignCohostUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, attendeeID: String) async throws -> ActivityDetail {
        try await repository.assignCohost(activityID: activityID, attendeeID: attendeeID)
    }
}
