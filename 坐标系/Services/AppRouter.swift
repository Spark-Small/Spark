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
    case communityPost(CommunityPost.ID)

    init?(notification link: NotificationDeepLink) {
        switch link {
        case .activity(let id, let followUp):
            self = .activity(id, followUp: followUp)
        case .conversation(let id):
            self = .conversation(id)
        case .booking(let id):
            self = .booking(id)
        case .communityPost(let id):
            self = .communityPost(id)
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
    /// 广场帖深链：独立 Tab 或活动内嵌 Feed 消费。
    var pendingCommunityPostID: CommunityPost.ID?
    /// 软启动合并 Tab 时，先推进活动栈内的广场入口。
    var pendingOpenEmbeddedCommunityFeed = false

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
        case .communityPost(let id):
            pendingCommunityPostID = id
            // 合并 Tab 时由 `openCommunityPost` 改切活动；本路径仅作兜底。
            selectedTab = .community
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
        pendingCommunityPostID = nil
        pendingOpenEmbeddedCommunityFeed = false
    }
}
