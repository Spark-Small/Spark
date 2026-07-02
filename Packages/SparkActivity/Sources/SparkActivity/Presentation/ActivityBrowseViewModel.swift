// Module: SparkActivity — Browse list state.

import Foundation
import SparkCore

@MainActor
@Observable
public final class ActivityBrowseViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var items: [ActivityItem] = []
    private(set) var isLoadingMore = false

    var selectedFilter: ActivityBrowseFilter = .all {
        didSet {
            guard selectedFilter != oldValue else { return }
            Task { await reload() }
        }
    }

    private let fetchBrowsePage: any FetchActivityBrowsePageUseCaseProtocol
    private let blockedHostsStore: BlockedActivityHostsStore
    private var nextCursor: String?
    private var loadGeneration = 0

    public init(
        fetchBrowsePage: any FetchActivityBrowsePageUseCaseProtocol,
        blockedHostsStore: BlockedActivityHostsStore
    ) {
        self.fetchBrowsePage = fetchBrowsePage
        self.blockedHostsStore = blockedHostsStore
    }

    public convenience init(
        repository: any ActivityBrowseRepository,
        blockedHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore()
    ) {
        self.init(
            fetchBrowsePage: FetchActivityBrowsePageUseCase(repository: repository),
            blockedHostsStore: blockedHostsStore
        )
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await reload()
    }

    func reload() async {
        loadGeneration += 1
        let generation = loadGeneration
        loadState = .loading
        nextCursor = nil
        do {
            let query = browseQuery(cursor: nil)
            let page = try await fetchBrowsePage(query: query)
            guard generation == loadGeneration else { return }
            items = await filterBlockedHosts(page.items)
            nextCursor = page.nextCursor
            loadState = items.isEmpty ? .empty : .loaded
            IntegrationTelemetry.browseImpression(itemCount: items.count)
        } catch is CancellationError {
            guard generation == loadGeneration else { return }
            loadState = items.isEmpty ? .idle : .loaded
            return
        } catch {
            guard generation == loadGeneration else { return }
            loadState = .failure(error.localizedDescription)
        }
    }

    func loadMoreIfNeeded(currentItemID: String) async {
        guard !isLoadingMore, let cursor = nextCursor else { return }
        guard items.last?.id == currentItemID else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let query = browseQuery(cursor: cursor)
            let page = try await fetchBrowsePage(query: query)
            items.append(contentsOf: await filterBlockedHosts(page.items))
            nextCursor = page.nextCursor
        } catch {
            // REASONING: Pagination failure is non-fatal; user can pull to reload later.
        }
    }

    /// Updates a browse row after a successful discover-sheet RSVP.
    func applyJoinedDetail(_ detail: ActivityDetail) {
        guard let index = items.firstIndex(where: { $0.id == detail.id }) else { return }
        items[index] = detail.asListItem()
    }

    private func browseQuery(cursor: String?) -> ActivityBrowseQuery {
        ActivityBrowseQuery(
            category: selectedFilter.apiCategoryValue,
            startsAfter: selectedFilter.startsAfter,
            startsBefore: selectedFilter.startsBefore,
            cursor: cursor
        )
    }

    private func filterBlockedHosts(_ items: [ActivityItem]) async -> [ActivityItem] {
        var visible: [ActivityItem] = []
        for item in items {
            if await !blockedHostsStore.isBlocked(hostID: item.hostID) {
                visible.append(item)
            }
        }
        return visible
    }
}
