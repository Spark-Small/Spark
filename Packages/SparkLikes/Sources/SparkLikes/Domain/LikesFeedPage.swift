// Module: SparkLikes — Paginated discover feed page.

import Foundation

public struct LikesFeedPage: Sendable, Equatable {
    public let items: [DiscoverCard]
    public let nextCursor: String?

    public init(items: [DiscoverCard], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}
