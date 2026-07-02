// Module: SparkBuddy — Loads a page of companion listings.

import Foundation

public struct FetchBuddyListingsUseCase: FetchBuddyListingsUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository

    public init(repository: any BuddyRepository) {
        self.repository = repository
    }

    public func callAsFunction(query: BuddyListQuery) async throws -> BuddyListPage {
        try await repository.fetchListings(query: query)
    }
}
