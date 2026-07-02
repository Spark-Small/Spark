// Module: SparkBuddy — Paginated review list page.

import Foundation

public struct BuddyReviewPage: Sendable, Equatable {
    public let items: [BuddyReview]
    public let page: Int
    public let pageSize: Int
    public let totalCount: Int
    public let hasMore: Bool

    public init(
        items: [BuddyReview],
        page: Int,
        pageSize: Int,
        totalCount: Int,
        hasMore: Bool
    ) {
        self.items = items
        self.page = page
        self.pageSize = pageSize
        self.totalCount = totalCount
        self.hasMore = hasMore
    }
}

public struct BuddyReviewQuery: Sendable, Equatable {
    public let listingID: String
    public let page: Int
    public let pageSize: Int

    public init(listingID: String, page: Int = 1, pageSize: Int = 10) {
        self.listingID = listingID
        self.page = max(1, page)
        self.pageSize = min(50, max(1, pageSize))
    }
}
