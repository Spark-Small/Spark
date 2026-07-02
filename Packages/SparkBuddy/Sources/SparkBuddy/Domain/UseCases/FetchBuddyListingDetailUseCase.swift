// Module: SparkBuddy — Loads a single companion listing.

import Foundation

public struct FetchBuddyListingDetailUseCase: FetchBuddyListingDetailUseCaseProtocol, Sendable {
    private let repository: any BuddyRepository

    public init(repository: any BuddyRepository) {
        self.repository = repository
    }

    public func callAsFunction(id: String) async throws -> BuddyListing {
        try await repository.fetchListing(id: id)
    }
}
