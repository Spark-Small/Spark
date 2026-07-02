// Module: SparkActivity — Tab bar bottom accessory presentation per screen context.

import Foundation

/// Drives label, icon, and enabled state for `ActivityTabBottomAccessory`.
public enum ActivityTabBottomAccessoryKind: Equatable, Hashable, Sendable {
    case hidden
    case createActivity(guest: Bool)
    case signInToRSVP
    case rsvpGoing(isEnabled: Bool)

    public var isVisible: Bool {
        self != .hidden
    }

    public var title: String {
        switch self {
        case .hidden:
            ""
        case .createActivity(let guest):
            if guest {
                String(
                    localized: "activity.create.host.cta.guest",
                    defaultValue: "登录后发起活动",
                    comment: "Guest create activity tab accessory"
                )
            } else {
                String(
                    localized: "activity.create.host.cta",
                    defaultValue: "发起活动",
                    comment: "Host a new activity from discover tab bar accessory"
                )
            }
        case .signInToRSVP:
            ActivityRSVPStatus.guestSignInToRSVPLabel
        case .rsvpGoing:
            String(
                localized: "activity.rsvp.going",
                defaultValue: "参加",
                comment: "RSVP going from tab accessory"
            )
        }
    }

    public var systemImage: String {
        switch self {
        case .hidden:
            "circle"
        case .createActivity:
            "plus.circle.fill"
        case .signInToRSVP:
            "person.crop.circle.badge.plus"
        case .rsvpGoing:
            "checkmark.circle.fill"
        }
    }

    public var accessibilityHint: String {
        switch self {
        case .hidden:
            ""
        case .createActivity(let guest):
            if guest {
                String(
                    localized: "activity.create.host.cta.guest.hint",
                    defaultValue: "登录后即可创建并发布活动",
                    comment: "Guest create activity accessory hint"
                )
            } else {
                String(
                    localized: "activity.create.host.cta.hint",
                    defaultValue: "创建并发布新的活动",
                    comment: "Create activity accessory hint"
                )
            }
        case .signInToRSVP:
            String(
                localized: "activity.guest.rsvp.signIn.going.hint",
                defaultValue: "登录后即可确认参加活动",
                comment: "Sign in to RSVP tab accessory hint"
            )
        case .rsvpGoing:
            String(
                localized: "activity.rsvp.going.hint",
                defaultValue: "确认你将参加此活动",
                comment: "RSVP going tab accessory hint"
            )
        }
    }

    public var isInteractionEnabled: Bool {
        switch self {
        case .hidden:
            false
        case .createActivity, .signInToRSVP:
            true
        case .rsvpGoing(let isEnabled):
            isEnabled
        }
    }
}
