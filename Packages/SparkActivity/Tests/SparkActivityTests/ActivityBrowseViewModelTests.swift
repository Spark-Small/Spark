// Module: SparkActivityTests

import Foundation
@testable import SparkActivity
import Testing

@MainActor
struct ActivityBrowseViewModelTests {
    @Test
    func reload_appliesStableCategoryFilter() async {
        let repository = RecordingBrowseRepository()
        let viewModel = ActivityBrowseViewModel(repository: repository)
        viewModel.selectedFilter = .social
        await waitForBrowseTerminalState(viewModel)

        #expect(viewModel.loadState == .loaded)
        #expect(repository.lastQuery?.category == ActivityBrowseFilter.social.apiCategoryValue)
        #expect(repository.lastQuery?.category == "社交")
        #expect(repository.lastQuery?.startsAfter == nil)
    }

    @Test
    func reload_appliesTodayWindow() async {
        let repository = RecordingBrowseRepository()
        let viewModel = ActivityBrowseViewModel(repository: repository)
        viewModel.selectedFilter = .today
        await waitForBrowseTerminalState(viewModel)

        #expect(viewModel.loadState == .loaded)
        #expect(repository.lastQuery?.category == nil)
        #expect(repository.lastQuery?.startsAfter != nil)
        #expect(repository.lastQuery?.startsBefore != nil)
    }

    @Test
    func reload_returnsLoadedItems() async {
        let repository = RecordingBrowseRepository()
        let viewModel = ActivityBrowseViewModel(repository: repository)

        await viewModel.reload()
        await waitForBrowseTerminalState(viewModel)

        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.title == "Test")
    }

    @Test
    func reload_emptyResults_setsEmptyState() async {
        let repository = RecordingBrowseRepository(items: [])
        let viewModel = ActivityBrowseViewModel(repository: repository)

        await viewModel.reload()
        await waitForBrowseTerminalState(viewModel)

        #expect(viewModel.loadState == .empty)
        #expect(viewModel.items.isEmpty)
    }

    @Test
    func staleReload_doesNotOverwriteNewerFilter() async {
        let repository = DelayedBrowseRepository(delayNanoseconds: 200_000_000)
        let viewModel = ActivityBrowseViewModel(repository: repository)

        async let firstReload: Void = viewModel.reload()
        viewModel.selectedFilter = .events
        await firstReload
        await waitForBrowseTerminalState(viewModel)

        #expect(repository.lastQuery?.category == "活动")
        #expect(viewModel.items.count == 1)
        #expect(viewModel.items.first?.category == "活动")
    }

    @Test
    func applyJoinedDetailUpdatesMatchingRow() async {
        let seedItem = ActivityItem(
            id: "act_1",
            title: "Test",
            summary: "",
            category: "社交",
            startsAt: Date(),
            locationName: "Park",
            hostDisplayName: "Host",
            attendeeCount: 2,
            capacity: 8,
            rsvpStatus: .invited
        )
        let repository = RecordingBrowseRepository(items: [seedItem])
        let viewModel = ActivityBrowseViewModel(repository: repository)
        await viewModel.reload()
        await waitForBrowseTerminalState(viewModel)

        guard let detail = MockActivityCatalog.detail(id: "act_1") else {
            Issue.record("Missing mock detail")
            return
        }
        let joined = detail.updatingRSVP(.going)

        viewModel.applyJoinedDetail(joined)

        #expect(viewModel.items.first?.id == joined.id)
        #expect(viewModel.items.first?.rsvpStatus == .going)
        if let item = viewModel.items.first {
            #expect(!ActivityBrowseJoinPolicy.showsJoinButton(for: item))
        }
    }
}

@MainActor
private func waitForBrowseTerminalState(_ viewModel: ActivityBrowseViewModel) async {
    for _ in 0 ..< 200 {
        switch viewModel.loadState {
        case .loaded, .empty, .failure:
            return
        case .idle, .loading:
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(5))
        }
    }
    Issue.record("Timed out waiting for browse load; state=\(viewModel.loadState)")
}

@MainActor
// REASONING: Test double records last query from unstructured concurrent reload tests.
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
        ActivityItem(
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

@MainActor
private final class DelayedBrowseRepository: ActivityBrowseRepository, @unchecked Sendable {
    private(set) var lastQuery: ActivityBrowseQuery?
    private let delayNanoseconds: UInt64

    init(delayNanoseconds: UInt64) {
        self.delayNanoseconds = delayNanoseconds
    }

    func fetchBrowse(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage {
        lastQuery = query
        try await Task.sleep(nanoseconds: delayNanoseconds)
        let category = query.category ?? "全部"
        let item = ActivityItem(
            id: "act_delayed",
            title: category,
            summary: "",
            category: category,
            startsAt: Date(),
            locationName: "Test",
            hostDisplayName: "Host",
            attendeeCount: 1,
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        return ActivityBrowsePage(items: [item], nextCursor: nil)
    }
}
