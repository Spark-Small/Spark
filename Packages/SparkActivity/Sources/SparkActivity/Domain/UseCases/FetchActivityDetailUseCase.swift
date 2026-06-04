// Module: SparkActivity — Loads a single activity invitation.

import Foundation

struct FetchActivityDetailUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String) async throws -> ActivityDetail {
        try await repository.fetchActivity(id: activityID)
    }
}
