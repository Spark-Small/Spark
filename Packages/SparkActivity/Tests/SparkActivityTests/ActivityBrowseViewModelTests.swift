// Module: SparkActivityTests

import Foundation
@testable import SparkActivity
import Testing

@MainActor
struct ActivityBrowseViewModelTests {
    @Test
    func reload_appliesCategoryAndTimeWindow() async {
        let repository = RecordingBrowseRepository()
        let viewModel = ActivityBrowseViewModel(repository: repository)
        viewModel.selectedCategory = "社交"
        viewModel.selectedTimeWindow = .thisWeek

        await viewModel.reload()

        #expect(viewModel.loadState == .loaded)
        #expect(repository.lastQuery?.category == "社交")
        #expect(repository.lastQuery?.startsAfter != nil)
        #expect(repository.lastQuery?.startsBefore != nil)
    }

    @Test
    func reload_emptyResults_setsEmptyState() async {
        let repository = RecordingBrowseRepository(items: [])
        let viewModel = ActivityBrowseViewModel(repository: repository)

        await viewModel.reload()

        #expect(viewModel.loadState == .empty)
        #expect(viewModel.items.isEmpty)
    }
}

@MainActor
private final class RecordingBrowseRepository: ActivityBrowseRepository, @unchecked Sendable {
    private(set) var lastQuery: ActivityBrowseQuery?
    private let items: [ActivityItem]

    init(items: [ActivityItem] = [RecordingBrowseRepository.defaultSampleItem()]) {
        self.items = items
    }

    func fetchBrowse(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage {
        lastQuery = query
        return ActivityBrowsePage(items: items, nextCursor: nil)
    }

    private static func defaultSampleItem() -> ActivityItem {
        if let detail = MockActivityCatalog.detail(id: "act_1") {
            return detail.asListItem()
        }
        return ActivityItem(
            id: "act_test",
            title: "Test",
            summary: "",
            category: "社交",
            startsAt: Date(),
            locationName: "Test",
            hostDisplayName: "Host",
            attendeeCount: 1,
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
    }
}
