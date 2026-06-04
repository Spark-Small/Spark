// Module: SparkActivity — Host cancels a scheduled activity.

import Foundation

struct CancelActivityUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(activityID: String) async throws -> ActivityDetail {
        try await repository.cancelActivity(activityID: activityID)
    }
}
