// Module: SparkSearchTests — Mock repository integration for Data layer coverage.

@testable import SparkSearch
import Testing

@MainActor
struct SearchMockRepositoryIntegrationTests {
    @Test func mockRepositoryReturnsResultsForKnownQuery() async throws {
        let repository = MockSearchRepository()
        let results = try await repository.search(query: "spark")
        #expect(results.isEmpty == false)
    }

    @Test func mockRepositoryReturnsEmptyForBlankQuery() async throws {
        let repository = MockSearchRepository()
        let results = try await repository.search(query: "   ")
        #expect(results.isEmpty)
    }

    @Test func searchCoordinatorBuildsViewModelWithInitialQuery() {
        let coordinator = SearchCoordinator(repository: MockSearchRepository())
        let viewModel = coordinator.makeViewModel(initialQuery: "hike")
        #expect(viewModel.query == "hike")
    }
}
