// Module: SparkBuddyTests — Browse ViewModel.

@testable import SparkBuddy
import Testing

@MainActor
struct BuddyViewModelTests {
    @Test func reloadLoadsMockCatalog() async {
        let viewModel = BuddyViewModel(repository: MockBuddyRepository())
        await viewModel.reload()
        #expect(viewModel.loadState == .loaded)
        #expect(!viewModel.items.isEmpty)
    }

    @Test func hourlyFilterNarrowsResults() async {
        let viewModel = BuddyViewModel(repository: MockBuddyRepository())
        viewModel.browseOptions.billingFilter = .hourly
        await viewModel.reload()
        #expect(viewModel.items.allSatisfy { $0.billingKind == .hourly })
    }

    @Test func cityWalkServiceFilterNarrowsResults() async {
        let viewModel = BuddyViewModel(repository: MockBuddyRepository())
        viewModel.selectedServiceFilter = .cityWalk
        await viewModel.reload()
        #expect(viewModel.items.allSatisfy { $0.serviceCategory == .cityWalk })
    }

    @Test func emptyFilterStillReturnsItems() async {
        let viewModel = BuddyViewModel(repository: MockBuddyRepository())
        viewModel.browseOptions.billingFilter = .all
        await viewModel.reload()
        #expect(viewModel.items.count >= 3)
    }
}
