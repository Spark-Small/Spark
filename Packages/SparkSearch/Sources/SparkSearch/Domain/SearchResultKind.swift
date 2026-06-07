// Module: SparkSearch — Stable search result categories (API wire values).

import Foundation

/// Machine-readable result type from `GET /v1/search` (`results[].kind`).
public enum SearchResultKind: String, Sendable, Equatable {
    case activity
    case community
    case person

    public init?(wireValue: String) {
        let normalized = wireValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let kind = SearchResultKind(rawValue: normalized) {
            self = kind
            return
        }
        // REASONING: Older mocks used localized labels in `kind`; keep navigation working.
        switch normalized {
        case "活动":
            self = .activity
        case "社区":
            self = .community
        case "用户", "人物":
            self = .person
        default:
            return nil
        }
    }

    public var supportsInAppNavigation: Bool {
        switch self {
        case .activity, .community, .person:
            true
        }
    }

    public var localizedLabel: String {
        switch self {
        case .activity:
            String(localized: "search.kind.activity", defaultValue: "活动", comment: "Result kind")
        case .community:
            String(localized: "search.kind.community", defaultValue: "社区", comment: "Result kind")
        case .person:
            String(localized: "search.kind.person", defaultValue: "用户", comment: "Result kind")
        }
    }
}

public extension SearchResultItem {
    var resultKind: SearchResultKind? {
        SearchResultKind(wireValue: kind)
    }
}
