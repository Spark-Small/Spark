// Module: SparkBuddy — Paginated reviews fetch.

import Foundation

public struct FetchBuddyReviewsUseCase: FetchBuddyReviewsUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository

    public init(repository: any BuddyRepository) {
        self.repository = repository
    }

    public func callAsFunction(query: BuddyReviewQuery) async throws -> BuddyReviewPage {
        try await repository.fetchReviews(query: query)
    }
}
