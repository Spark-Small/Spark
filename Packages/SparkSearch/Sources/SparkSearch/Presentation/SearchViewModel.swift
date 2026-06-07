// Module: SparkSearch — Search state.

import Foundation
import Observation

@MainActor
@Observable
public final class SearchViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    public static let defaultSuggestions: [String] = [
        String(localized: "search.suggestion.events", defaultValue: "附近活动", comment: "Search suggestion"),
        String(localized: "search.suggestion.groups", defaultValue: "跑步俱乐部", comment: "Search suggestion"),
        String(localized: "search.suggestion.people", defaultValue: "可能认识的人", comment: "Search suggestion")
    ]

    public var query: String = ""
    public private(set) var results: [SearchResultItem] = []
    public private(set) var loadState: LoadState = .idle

    private let searchQuery: any SearchQueryUseCaseProtocol

    public init(searchQuery: any SearchQueryUseCaseProtocol) {
        self.searchQuery = searchQuery
    }

    public convenience init(repository: any SearchRepository) {
        self.init(searchQuery: SearchQueryUseCase(repository: repository))
    }

    public func clearResults() {
        results = []
        loadState = .idle
    }

    public func submitSearch() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = []
            loadState = .idle
            return
        }
        loadState = .loading
        do {
            results = try await searchQuery(query: trimmed)
            loadState = results.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
