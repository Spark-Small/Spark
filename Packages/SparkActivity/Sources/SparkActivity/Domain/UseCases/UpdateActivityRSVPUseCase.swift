// Module: SparkActivity — Submits RSVP for an invite.

import Foundation

struct UpdateActivityRSVPUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String, status: ActivityRSVPStatus) async throws -> ActivityDetail {
        try await repository.updateRSVP(activityID: activityID, status: status)
    }
}
