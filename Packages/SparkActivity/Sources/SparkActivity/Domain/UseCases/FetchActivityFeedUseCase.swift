// Module: SparkActivity — Loads activity list.

import Foundation

struct FetchActivityFeedUseCase: Sendable {
    private let repository: any ActivityFeedRepository

    init(repository: any ActivityFeedRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> [ActivityItem] {
        try await repository.fetchActivities()
    }
}
