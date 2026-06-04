// Module: SparkAppShell — Primary tab identifiers.

import Foundation

public enum SparkTab: String, CaseIterable, Identifiable, Sendable {
    case likes
    case community
    case messages
    case activity
    case search

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .likes:
            String(localized: "tab.likes", defaultValue: "喜欢", comment: "Tab title")
        case .community:
            String(localized: "tab.community", defaultValue: "社区", comment: "Tab title")
        case .messages:
            String(localized: "tab.messages", defaultValue: "消息", comment: "Tab title")
        case .activity:
            String(localized: "tab.activity", defaultValue: "活动", comment: "Tab title")
        case .search:
            String(localized: "tab.search", defaultValue: "搜索", comment: "Tab title")
        }
    }

    public var systemImage: String {
        switch self {
        case .likes: "heart.fill"
        case .community: "person.2.fill"
        case .messages: "bubble.left.and.bubble.right.fill"
        case .activity: "calendar"
        case .search: "magnifyingglass"
        }
    }

    /// Tabs that require a signed-in user (guests are redirected to login).
    public var requiresAuthentication: Bool {
        switch self {
        case .search:
            false
        case .likes, .community, .messages, .activity:
            true
        }
    }
}
