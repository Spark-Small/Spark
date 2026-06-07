// Module: SparkAppShell — Primary tab identifiers.

import Foundation

public enum SparkTab: String, CaseIterable, Identifiable, Sendable {
    case likes
    case community
    case messages
    case activity
    case profile

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
        case .profile:
            String(localized: "tab.profile", defaultValue: "我的", comment: "Tab title")
        }
    }

    /// Unselected tab bar symbol (HIG: outline when inactive).
    public var systemImage: String {
        switch self {
        case .likes: "heart"
        case .community: "person.2"
        case .messages: "bubble.left.and.bubble.right"
        case .activity: "calendar"
        case .profile: "person.crop.circle"
        }
    }

    /// Selected tab bar symbol (HIG: filled when active).
    public var selectedSystemImage: String {
        switch self {
        case .likes: "heart.fill"
        case .community: "person.2.fill"
        case .messages: "bubble.left.and.bubble.right.fill"
        case .activity: "calendar"
        case .profile: "person.crop.circle.fill"
        }
    }

    /// Tabs that require a signed-in user (guests are redirected to login).
    public var requiresAuthentication: Bool {
        switch self {
        case .profile:
            false
        case .likes, .community, .messages, .activity:
            true
        }
    }

    /// Legacy deep-link name for search entry (routes to profile tab).
    public static func fromDeepLinkName(_ name: String) -> SparkTab? {
        if name == "search" { return .profile }
        return SparkTab(rawValue: name)
    }
}
