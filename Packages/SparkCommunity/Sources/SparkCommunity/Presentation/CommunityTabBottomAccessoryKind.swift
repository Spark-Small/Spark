// Module: SparkCommunity — Tab bar bottom accessory presentation per screen context.

import Foundation

/// Drives label, icon, and enabled state for the community tab bottom accessory.
public enum CommunityTabBottomAccessoryKind: Equatable, Sendable {
    case hidden
    case composePost(guest: Bool)

    public var isVisible: Bool {
        self != .hidden
    }

    public var title: String {
        switch self {
        case .hidden:
            ""
        case .composePost(let guest):
            if guest {
                String(
                    localized: "community.compose.cta.guest",
                    defaultValue: "登录后发帖",
                    comment: "Guest compose post tab accessory"
                )
            } else {
                String(
                    localized: "community.compose.cta",
                    defaultValue: "发帖",
                    comment: "Compose post tab accessory"
                )
            }
        }
    }

    public var systemImage: String {
        switch self {
        case .hidden:
            "circle"
        case .composePost:
            "square.and.pencil"
        }
    }

    public var accessibilityHint: String {
        switch self {
        case .hidden:
            ""
        case .composePost(let guest):
            if guest {
                String(
                    localized: "community.compose.cta.guest.hint",
                    defaultValue: "登录后即可发布社区动态",
                    comment: "Guest compose post accessory hint"
                )
            } else {
                String(
                    localized: "community.compose.cta.hint",
                    defaultValue: "撰写并发布一条社区动态",
                    comment: "Compose post accessory hint"
                )
            }
        }
    }

    public var isInteractionEnabled: Bool {
        switch self {
        case .hidden:
            false
        case .composePost:
            true
        }
    }
}
