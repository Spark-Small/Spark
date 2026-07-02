// Module: SparkBuddyTests — Paginated review fetch.

import Foundation
import Testing
@testable import SparkBuddy

struct BuddyReviewPaginationTests {
    @Test func mockPagination_firstPage() async throws {
        let repository = MockBuddyRepository()
        let page = try await repository.fetchReviews(
            query: BuddyReviewQuery(listingID: "buddy_city_1", page: 1, pageSize: 10)
        )
        #expect(page.items.count == 10)
        #expect(page.totalCount == 54)
        #expect(page.hasMore)
        #expect(page.page == 1)
    }

    @Test func mockPagination_lastPage() async throws {
        let repository = MockBuddyRepository()
        let page = try await repository.fetchReviews(
            query: BuddyReviewQuery(listingID: "buddy_city_1", page: 6, pageSize: 10)
        )
        #expect(page.items.count == 4)
        #expect(!page.hasMore)
    }

    @Test func buddyAPIPath_reviewsBuildsPaginatedPath() {
        let path = BuddyAPIPath.reviews(listingID: "listing_1", page: 2, pageSize: 10)
        #expect(path?.contains("reviews") == true)
        #expect(path?.contains("page=2") == true)
        #expect(path?.contains("page_size=10") == true)
    }
}
