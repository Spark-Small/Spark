// Module: SparkActivityTests

@testable import SparkActivity
import Testing

@MainActor
struct ActivityViewModelFilterTests {
    @Test func filteredItemsRespectsListFilter() async {
        let viewModel = ActivityViewModel(repository: MockActivityFeedRepository())
        await viewModel.load()
        viewModel.listFilter = .pendingReply
        let pending = viewModel.filteredItems
        #expect(pending.allSatisfy { $0.rsvpStatus == .invited })
        #expect(pending.contains { $0.id == "act_2" })

        viewModel.listFilter = .upcoming
        let upcoming = viewModel.filteredItems
        #expect(upcoming.allSatisfy { $0.rsvpStatus == .going || $0.rsvpStatus == .maybe })
        #expect(upcoming.contains { $0.id == "act_1" })

        viewModel.listFilter = .hosting
        let hosting = viewModel.filteredItems
        #expect(hosting.allSatisfy { $0.rsvpStatus == .host })
        #expect(hosting.contains { $0.id == "act_3" })
    }

    @Test func loadPopulatesFourMockActivities() async {
        let viewModel = ActivityViewModel(repository: MockActivityFeedRepository())
        await viewModel.load()
        #expect(viewModel.items.count == 7)
    }
}
