// Module: SparkActivity — Public activity discovery (MODULE-D).

import Foundation

/// Filters for `GET /v1/activities/browse`.
public struct ActivityBrowseQuery: Sendable, Equatable {
    public var category: String?
    public var startsAfter: Date?
    public var startsBefore: Date?
    public var cursor: String?

    public init(
        category: String? = nil,
        startsAfter: Date? = nil,
        startsBefore: Date? = nil,
        cursor: String? = nil
    ) {
        self.category = category
        self.startsAfter = startsAfter
        self.startsBefore = startsBefore
        self.cursor = cursor
    }
}

public struct ActivityBrowsePage: Sendable, Equatable {
    public let items: [ActivityItem]
    public let nextCursor: String?

    public init(items: [ActivityItem], nextCursor: String?) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

/// Browse / discover public scheduled activities (separate from inbox feed).
public protocol ActivityBrowseRepository: Sendable {
    func fetchBrowse(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage
}
