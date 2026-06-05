// Module: SparkActivity — Mock public activity browse.

import Foundation

public struct MockActivityBrowseRepository: ActivityBrowseRepository, Sendable {
    public init() {}

    public func fetchBrowse(query: ActivityBrowseQuery) async throws -> ActivityBrowsePage {
        var items = MockActivityCatalog.allDetails()
            .filter { $0.lifecycleStatus != .cancelled && $0.lifecycleStatus != .ended }
            .map { $0.asListItem() }

        if let category = query.category, !category.isEmpty {
            items = items.filter { $0.category == category }
        }
        if let after = query.startsAfter {
            items = items.filter { ($0.startsAt ?? .distantPast) >= after }
        }
        if let before = query.startsBefore {
            items = items.filter { ($0.startsAt ?? .distantFuture) <= before }
        }
        items.sort { ($0.startsAt ?? .distantFuture) < ($1.startsAt ?? .distantFuture) }

        if let cursor = query.cursor,
           let index = items.firstIndex(where: { $0.id == cursor }) {
            items = Array(items.dropFirst(index + 1))
        }

        let pageSize = 20
        let page = Array(items.prefix(pageSize))
        let nextCursor = items.count > pageSize ? page.last?.id : nil
        return ActivityBrowsePage(items: page, nextCursor: nextCursor)
    }
}
