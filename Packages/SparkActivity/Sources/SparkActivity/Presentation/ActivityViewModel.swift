// Module: SparkActivity — Activity inbox list state.

import Foundation
import Observation

@MainActor
@Observable
public final class ActivityViewModel {
    enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    private(set) var items: [ActivityItem] = []
    private(set) var loadState: LoadState = .idle
    var listFilter: ActivityListFilter = .all

    private let fetchActivities: any FetchActivityFeedUseCaseProtocol
    private var loadGeneration = 0

    public init(fetchActivities: any FetchActivityFeedUseCaseProtocol) {
        self.fetchActivities = fetchActivities
    }

    public convenience init(repository: any ActivityFeedRepository) {
        self.init(fetchActivities: FetchActivityFeedUseCase(repository: repository))
    }

    var filteredItems: [ActivityItem] {
        items.filter { ActivityListFiltering.matches($0, filter: listFilter) }
    }

    var showsFilterEmptyState: Bool {
        loadState == .loaded && !items.isEmpty && filteredItems.isEmpty
    }

    func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        loadState = .loading
        do {
            let fetched = try await fetchActivities()
            guard generation == loadGeneration else { return }
            items = fetched
            loadState = items.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            guard generation == loadGeneration else { return }
            loadState = items.isEmpty ? .idle : .loaded
            return
        } catch {
            guard generation == loadGeneration else { return }
            loadState = .failure(error.localizedDescription)
        }
    }
}
