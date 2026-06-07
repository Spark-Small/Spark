// Module: SparkSearchTests — Search use case coverage.

@testable import SparkSearch
import Testing

struct SearchUseCaseTests {
    @Test func searchQueryUseCaseReturnsResults() async throws {
        let useCase = SearchQueryUseCase(repository: MockSearchRepository())
        let results = try await useCase(query: "spark")
        #expect(!results.isEmpty)
    }

    @Test func searchQueryUseCaseEmptyQueryReturnsEmpty() async throws {
        let useCase = SearchQueryUseCase(repository: MockSearchRepository())
        let results = try await useCase(query: "")
        #expect(results.isEmpty)
    }
}
