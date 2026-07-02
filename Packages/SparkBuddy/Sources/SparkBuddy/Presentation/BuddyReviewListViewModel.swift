// Module: SparkBuddy — Paginated review list state.

import Foundation
import OSLog
import SparkCore

@MainActor
@Observable
public final class BuddyReviewListViewModel {
    private let logger = SparkLog.logger(category: "BuddyReviews")

    enum ViewState: Equatable {
        case loading
        case loaded
        case failure(String)
    }

    let listingID: String
    let reviewCount: Int

    private(set) var state: ViewState = .loading
    private(set) var reviews: [BuddyReview] = []
    private(set) var hasMore = true
    private(set) var isLoadingMore = false

    private let fetchReviews: any FetchBuddyReviewsUseCaseProtocol
    private let pageSize: Int
    private var nextPage = 1

    public init(
        listingID: String,
        reviewCount: Int,
        fetchReviews: any FetchBuddyReviewsUseCaseProtocol,
        pageSize: Int = 10
    ) {
        self.listingID = listingID
        self.reviewCount = reviewCount
        self.fetchReviews = fetchReviews
        self.pageSize = pageSize
    }

    func loadInitialIfNeeded() async {
        guard reviews.isEmpty else { return }
        await reload()
    }

    func reload() async {
        state = .loading
        nextPage = 1
        hasMore = true
        reviews = []
        await loadNextPage()
    }

    func loadMoreIfNeeded(for review: BuddyReview) async {
        guard hasMore, !isLoadingMore, review.id == reviews.last?.id else { return }
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard hasMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let page = try await fetchReviews(
                query: BuddyReviewQuery(
                    listingID: listingID,
                    page: nextPage,
                    pageSize: pageSize
                )
            )
            if nextPage == 1, page.items.isEmpty {
                state = .failure(
                    String(
                        localized: "buddy.reviews.empty",
                        defaultValue: "暂无评价",
                        comment: "Empty reviews state"
                    )
                )
                hasMore = false
                return
            }
            reviews.append(contentsOf: page.items)
            hasMore = page.hasMore
            nextPage = page.page + 1
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            logger.error("Failed to load buddy reviews: \(error.localizedDescription, privacy: .public)")
            if reviews.isEmpty {
                state = .failure(error.localizedDescription)
            }
        }
    }
}
