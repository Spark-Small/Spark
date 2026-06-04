// Module: SparkActivity — Join waitlist when activity is full.

import Foundation

struct JoinActivityWaitlistUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String) async throws -> ActivityDetail {
        try await repository.joinWaitlist(activityID: activityID)
    }
}
