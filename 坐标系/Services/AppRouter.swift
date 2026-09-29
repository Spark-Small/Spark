//
//  AppRouter.swift
//  坐标系
//
//  跨 Tab 深链与待消费导航意图（单一容器，由 AppModel 协调 Tab 切换）。
//

import Foundation
import CoordinateModels

enum BuddiesRoute: Hashable {
    case clubDiscover
}

enum AppDeepLink: Equatable {
    case activity(Activity.ID, followUp: ActivityNotificationFollowUp = .none)
    case conversation(
        ChatConversation.ID,
        focusMessageID: ChatMessage.ID? = nil,
        callID: CallSessionRecord.ID? = nil
    )
    case booking(BuddyBookingRecord.ID?)
    case profile(ProfileRoute)
    case buddies(BuddiesRoute)

    init?(notification link: NotificationDeepLink) {
        switch link {
        case .activity(let id, let followUp):
            self = .activity(id, followUp: followUp)
        case .conversation(let id):
            self = .conversation(id)
        case .booking(let id):
            self = .booking(id)
        }
    }
}

@MainActor
@Observable
final class AppRouter {
    var pendingConversationID: ChatConversation.ID?
    var pendingFocusMessageID: ChatMessage.ID?
    var pendingCallID: CallSessionRecord.ID?
    var pendingActivityID: Activity.ID?
    var pendingActivityFollowUp: ActivityNotificationFollowUp = .none
    /// 行程页尚未出现时暂存，由 `ActivityCredentialExpandedView` 消费
    var pendingActivityJourneyFollowUp: ActivityNotificationFollowUp = .none
    var pendingBookingID: BuddyBookingRecord.ID?
    var pendingProfileRoute: ProfileRoute?
    var pendingBuddiesRoute: BuddiesRoute?

    func apply(_ link: AppDeepLink, selectedTab: inout AppTab) {
        switch link {
        case .activity(let id, let followUp):
            pendingActivityID = id
            pendingActivityFollowUp = followUp
            selectedTab = .activities
        case .conversation(let id, let focus, let call):
            pendingConversationID = id
            pendingFocusMessageID = focus
            pendingCallID = call
            selectedTab = .messages
        case .booking(let id):
            pendingBookingID = id
            pendingProfileRoute = id.map { .bookingDetail($0) } ?? .bookingCredentials
            selectedTab = .profile
        case .profile(let route):
            pendingProfileRoute = route
            selectedTab = .profile
        case .buddies(let route):
            pendingBuddiesRoute = route
            selectedTab = .buddies
        }
    }

    func clearPendingIntents() {
        pendingConversationID = nil
        pendingFocusMessageID = nil
        pendingCallID = nil
        pendingActivityID = nil
        pendingActivityFollowUp = .none
        pendingActivityJourneyFollowUp = .none
        pendingBookingID = nil
        pendingProfileRoute = nil
        pendingBuddiesRoute = nil
    }
}
