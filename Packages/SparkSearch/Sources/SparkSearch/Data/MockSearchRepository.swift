// Module: SparkSearch — Mock search for previews and mock API host.

import Foundation

public struct MockSearchRepository: SearchRepository, Sendable {
    public init() {}

    public func search(query: String) async throws -> [SearchResultItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return [
            SearchResultItem(
                id: "act_1",
                title: String(
                    localized: "search.mock.result.1.title",
                    defaultValue: "周末徒步",
                    comment: "Search result"
                ),
                subtitle: String(
                    localized: "search.mock.result.1.subtitle",
                    defaultValue: "活动 · 周六",
                    comment: "Search result subtitle"
                ),
                kind: SearchResultKind.activity.rawValue
            ),
            SearchResultItem(
                id: "cp_2",
                title: trimmed,
                subtitle: String(
                    localized: "search.mock.result.2.subtitle",
                    defaultValue: "社区讨论",
                    comment: "Search result subtitle"
                ),
                kind: SearchResultKind.community.rawValue
            ),
        ]
    }
}
