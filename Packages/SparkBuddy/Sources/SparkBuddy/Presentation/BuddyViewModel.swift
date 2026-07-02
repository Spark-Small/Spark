// Module: SparkBuddy — Browse list state.

import Foundation
import OSLog
import SparkCore

@MainActor
@Observable
public final class BuddyViewModel {
    private let logger = SparkLog.logger(category: "BuddyBrowse")
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    private(set) var loadState: LoadState = .idle
    private(set) var items: [BuddyListing] = []
    private(set) var isLoadingMore = false

    var selectedServiceFilter: BuddyServiceFilter = .all {
        didSet {
            guard selectedServiceFilter != oldValue else { return }
            BuddyTelemetry.serviceFilterChanged(filter: selectedServiceFilter.rawValue)
            Task { await reload() }
        }
    }

    var browseOptions = BuddyBrowseOptions() {
        didSet {
            guard browseOptions != oldValue else { return }
            if browseOptions.billingFilter != oldValue.billingFilter {
                BuddyTelemetry.billingFilterChanged(filter: browseOptions.billingFilter.rawValue)
                Task { await reload() }
            } else {
                applyBrowseOptions()
            }
        }
    }

    private var fetchedItems: [BuddyListing] = []
    private let fetchListings: any FetchBuddyListingsUseCaseProtocol
    private var nextCursor: String?
    private var loadGeneration = 0

    public init(fetchListings: any FetchBuddyListingsUseCaseProtocol) {
        self.fetchListings = fetchListings
    }

    public convenience init(repository: any BuddyRepository) {
        self.init(fetchListings: FetchBuddyListingsUseCase(repository: repository))
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
            let query = BuddyListQuery(
                serviceFilter: selectedServiceFilter,
                billingFilter: browseOptions.billingFilter,
                cursor: nil
            )
            let page = try await fetchListings(query: query)
            guard generation == loadGeneration else { return }
            fetchedItems = page.items
            applyBrowseOptions()
            nextCursor = page.nextCursor
            loadState = items.isEmpty ? .empty : .loaded
            BuddyTelemetry.browseImpression(
                itemCount: items.count,
                serviceFilter: selectedServiceFilter.rawValue,
                billingFilter: browseOptions.billingFilter.rawValue
            )
        } catch is CancellationError {
            guard generation == loadGeneration else { return }
            loadState = items.isEmpty ? .idle : .loaded
        } catch {
            guard generation == loadGeneration else { return }
            logger.error("Buddy browse reload failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(AppError(buddyUnderlying: error).localizedDescription)
        }
    }

    func loadMoreIfNeeded(currentItemID: String) async {
        guard !isLoadingMore, let cursor = nextCursor else { return }
        guard items.last?.id == currentItemID else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let query = BuddyListQuery(
                serviceFilter: selectedServiceFilter,
                billingFilter: browseOptions.billingFilter,
                cursor: cursor
            )
            let page = try await fetchListings(query: query)
            fetchedItems.append(contentsOf: page.items)
            applyBrowseOptions()
            nextCursor = page.nextCursor
        } catch {
            logger.warning("Buddy browse pagination failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    func resetBrowseOptions() {
        browseOptions = BuddyBrowseOptions()
    }

    private func applyBrowseOptions() {
        items = Self.filterAndSort(fetchedItems, options: browseOptions)
        if case .loaded = loadState {
            loadState = items.isEmpty ? .empty : .loaded
        }
    }

    nonisolated static func filterAndSort(_ listings: [BuddyListing], options: BuddyBrowseOptions) -> [BuddyListing] {
        var result = listings
        if options.verifiedOnly {
            result = result.filter { $0.isVerified || $0.trust?.isFullyVerified == true }
        }
        switch options.sortOrder {
        case .recommended:
            break
        case .match:
            result.sort { ($0.matchInsight?.matchPercent ?? 0) > ($1.matchInsight?.matchPercent ?? 0) }
        case .rating:
            result.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .priceAscending:
            result.sort { $0.priceAmount < $1.priceAmount }
        }
        return result
    }
}
