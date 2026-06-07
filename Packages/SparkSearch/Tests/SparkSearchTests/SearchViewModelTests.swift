// Module: SparkSearchTests

import Foundation
import SparkSearch
import Testing

@MainActor
struct SearchViewModelTests {
    @Test func submitSearchPopulatesResults() async {
        let viewModel = SearchViewModel(repository: MockSearchRepository())
        viewModel.query = "徒步"
        await viewModel.submitSearch()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.results.count == 3)
    }

    @Test func emptyQueryClearsResults() async {
        let viewModel = SearchViewModel(repository: MockSearchRepository())
        viewModel.query = "   "
        await viewModel.submitSearch()
        #expect(viewModel.loadState == .idle)
        #expect(viewModel.results.isEmpty)
    }

    @Test func submitSearchFailureSetsFailureState() async {
        let viewModel = SearchViewModel(repository: FailingSearchRepository())
        viewModel.query = "test"
        await viewModel.submitSearch()
        #expect(viewModel.loadState == .failure("Search unavailable"))
    }
}

private struct FailingSearchRepository: SearchRepository, Sendable {
    struct TestError: LocalizedError {
        var errorDescription: String? { "Search unavailable" }
    }

    func search(query: String) async throws -> [SearchResultItem] {
        throw TestError()
    }
}
