// Module: SparkActivity — Browse list state.

import Foundation
import SparkCore

@MainActor
@Observable
final class ActivityBrowseViewModel {
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

    var selectedCategory: String? {
        didSet {
            guard selectedCategory != oldValue else { return }
            Task { await reload() }
        }
    }

    var selectedTimeWindow: ActivityBrowseTimeWindow = .all {
        didSet {
            guard selectedTimeWindow != oldValue else { return }
            Task { await reload() }
        }
    }

    static let categoryOptions: [String?] = [
        nil,
        String(localized: "activity.category.event", defaultValue: "活动", comment: "Activity category"),
        String(localized: "activity.category.social", defaultValue: "社交", comment: "Social category")
    ]

    private let fetchBrowsePage: FetchActivityBrowsePageUseCase
    private var nextCursor: String?

    init(repository: any ActivityBrowseRepository) {
        fetchBrowsePage = FetchActivityBrowsePageUseCase(repository: repository)
    }

    func loadIfNeeded() async {
        guard loadState == .idle else { return }
        await reload()
    }

    func reload() async {
        loadState = .loading
        nextCursor = nil
        do {
            let query = browseQuery(cursor: nil)
            let page = try await fetchBrowsePage(query: query)
            items = page.items
            nextCursor = page.nextCursor
            loadState = page.items.isEmpty ? .empty : .loaded
            IntegrationTelemetry.browseImpression(itemCount: page.items.count)
        } catch is CancellationError {
            return
        } catch {
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
            items.append(contentsOf: page.items)
            nextCursor = page.nextCursor
        } catch {
            // REASONING: Pagination failure is non-fatal; user can pull to reload later.
        }
    }

    private func browseQuery(cursor: String?) -> ActivityBrowseQuery {
        ActivityBrowseQuery(
            category: selectedCategory,
            startsAfter: selectedTimeWindow.startsAfter,
            startsBefore: selectedTimeWindow.startsBefore,
            cursor: cursor
        )
    }
}
