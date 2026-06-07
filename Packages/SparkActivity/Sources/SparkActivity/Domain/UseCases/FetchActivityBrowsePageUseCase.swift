// Module: SparkActivity — Browse page fetch.

import Foundation

public struct FetchActivityBrowsePageUseCase: Sendable {
    private let repository: any ActivityBrowseRepository

    public init(repository: any ActivityBrowseRepository) {
        self.repository = repository
    }

    public func callAsFunction(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage {
        try await repository.fetchBrowse(query: query)
    }
}
