// Module: SparkActivityTests

@testable import SparkActivity
import Testing

@MainActor
struct ActivityViewModelTests {
    @Test func loadPopulatesItems() async {
        let viewModel = ActivityViewModel(repository: MockActivityFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.items.count == 5)
    }

    @Test func loadEmptySetsEmptyState() async {
        let viewModel = ActivityViewModel(repository: EmptyActivityFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .empty)
        #expect(viewModel.items.isEmpty)
    }

    @Test func loadFailureSetsFailureState() async {
        let viewModel = ActivityViewModel(repository: FailingActivityFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .failure("Feed unavailable"))
    }
}
