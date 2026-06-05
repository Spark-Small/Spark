// Module: SparkLikes — Loads daily pool + spark allowance.

import Foundation

struct FetchDailyLikeStatsUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction() async throws -> DailyLikeStats {
        try await repository.fetchDailyStats()
    }
}
