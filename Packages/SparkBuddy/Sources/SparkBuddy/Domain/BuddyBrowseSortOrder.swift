// Module: SparkBuddy — Client-side browse sort options (options sheet).

import Foundation

public enum BuddyBrowseSortOrder: String, CaseIterable, Identifiable, Sendable, Equatable {
    case recommended
    case match
    case rating
    case priceAscending

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .recommended:
            String(
                localized: "buddy.browse.sort.recommended",
                defaultValue: "推荐排序",
                comment: "Recommended sort"
            )
        case .match:
            String(
                localized: "buddy.browse.sort.match",
                defaultValue: "匹配度优先",
                comment: "Match sort"
            )
        case .rating:
            String(
                localized: "buddy.browse.sort.rating",
                defaultValue: "评分优先",
                comment: "Rating sort"
            )
        case .priceAscending:
            String(
                localized: "buddy.browse.sort.price",
                defaultValue: "价格从低到高",
                comment: "Price ascending sort"
            )
        }
    }
}

public struct BuddyBrowseOptions: Equatable, Sendable {
    public var billingFilter: BuddyBillingFilter
    public var verifiedOnly: Bool
    public var sortOrder: BuddyBrowseSortOrder

    public init(
        billingFilter: BuddyBillingFilter = .all,
        verifiedOnly: Bool = false,
        sortOrder: BuddyBrowseSortOrder = .recommended
    ) {
        self.billingFilter = billingFilter
        self.verifiedOnly = verifiedOnly
        self.sortOrder = sortOrder
    }

    public var hasActiveSecondaryFilters: Bool {
        billingFilter != .all || verifiedOnly || sortOrder != .recommended
    }
}
