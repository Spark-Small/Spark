// Module: SparkLikes — Loads discover feed page.

import Foundation

struct FetchLikesFeedUseCase: Sendable {
    private let repository: any LikesFeedRepository

    init(repository: any LikesFeedRepository) {
        self.repository = repository
    }

    func callAsFunction(query: LikesFeedQuery) async throws -> LikesFeedPage {
        try await repository.fetchFeed(query: query)
    }
}
