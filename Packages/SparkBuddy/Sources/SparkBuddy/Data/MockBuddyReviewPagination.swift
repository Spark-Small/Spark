// Module: SparkBuddy — Mock paginated reviews aligned with Live expansion.

import Foundation

enum MockBuddyReviewPagination {
    private static let authorNames = ["小林", "Mia", "阿哲", "Coco", "Leo"]

    static func page(for listing: BuddyListing, query: BuddyReviewQuery) -> BuddyReviewPage {
        let all = expandedReviews(for: listing)
        let totalCount = max(listing.reviewCount, all.count)
        let start = (query.page - 1) * query.pageSize
        let end = min(start + query.pageSize, all.count)
        let items = start < all.count ? Array(all[start..<end]) : []
        let hasMore = start + items.count < totalCount
        return BuddyReviewPage(
            items: items,
            page: query.page,
            pageSize: query.pageSize,
            totalCount: totalCount,
            hasMore: hasMore
        )
    }

    private static func expandedReviews(for listing: BuddyListing) -> [BuddyReview] {
        let base = listing.reviewSnapshot?.reviews ?? []
        let total = listing.reviewCount
        guard base.count < total else { return base }
        var expanded = base
        while expanded.count < total {
            let index = expanded.count
            expanded.append(
                BuddyReview(
                    id: "rv_mock_\(listing.id)_\(index)",
                    authorDisplayName: authorNames[index % authorNames.count],
                    rating: index.isMultiple(of: 5) ? 4 : 5,
                    comment: String(
                        format: String(
                            localized: "buddy.mock.review.generated.format",
                            defaultValue: "用户评价 #%lld：体验稳定可靠，值得推荐。",
                            comment: "Generated mock review body"
                        ),
                        locale: .current,
                        Int64(index + 1)
                    ),
                    createdAt: Calendar.current.date(byAdding: .day, value: -index, to: .now)
                )
            )
        }
        return expanded
    }
}
