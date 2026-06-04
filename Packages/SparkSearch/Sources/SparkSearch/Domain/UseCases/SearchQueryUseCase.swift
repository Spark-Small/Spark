// Module: SparkSearch — Executes a search query.

import Foundation

struct SearchQueryUseCase: Sendable {
    private let repository: any SearchRepository

    init(repository: any SearchRepository) {
        self.repository = repository
    }

    func callAsFunction(query: String) async throws -> [SearchResultItem] {
        try await repository.search(query: query)
    }
}
