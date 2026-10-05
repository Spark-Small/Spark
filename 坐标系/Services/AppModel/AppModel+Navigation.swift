//
//  AppModel+Navigation.swift
//  坐标系
//

import Foundation
import CoordinateModels

extension AppModel {
    func openMessages(
        conversationID: ChatConversation.ID,
        focusMessageID: ChatMessage.ID? = nil,
        callID: CallSessionRecord.ID? = nil
    ) {
        router.apply(
            .conversation(conversationID, focusMessageID: focusMessageID, callID: callID),
            selectedTab: &selectedTab
        )
    }

    /// 通知 / 深链：切到活动 Tab 并打开「我的行程」Zoom
    func openActivityJourney(_ id: Activity.ID) {
        selectedTab = .activities
        pendingActivityID = id
        pendingActivityFollowUp = .openJourney
    }

    /// 活动 Tab 底栏附件：打开地图导航 Sheet（由 `ActivitiesView` 消费）。
    func requestActivityMapNavigation(_ activity: Activity) {
        selectedTab = .activities
        mapNavigationActivity = activity
    }

    /// 无行程空态 / 发现引导：切到活动 Tab、套用发现落地筛选，并滚到货架顶部。
    func focusActivitiesDiscoverBrowse() {
        selectedTab = .activities
        activitiesDiscoverBrowseFocusToken += 1
        if let message = activities.applyDiscoverPromoLanding() {
            activities.flashLight(message)
        }
    }

    /// 通知 / 深链：切到活动 Tab 并打开详情
    func openActivity(_ id: Activity.ID) {
        router.apply(.activity(id), selectedTab: &selectedTab)
    }

    /// 通知：打开「我的 → 我的陪玩」（可定位到具体单）
    func openMyBookings(bookingID: BuddyBookingRecord.ID? = nil) {
        router.apply(.booking(bookingID), selectedTab: &selectedTab)
    }

    func openClubDiscover() {
        router.apply(.buddies(.clubDiscover), selectedTab: &selectedTab)
    }

    /// 行程下一步等：切到搭子 Tab 并打开「约陪玩」。
    func openPaidCompanionBrowse() {
        router.apply(.buddies(.paidBrowse), selectedTab: &selectedTab)
    }

    func handleNotificationDeepLink(_ link: NotificationDeepLink) {
        if case .communityPost(let id) = link {
            openCommunityPost(id)
            return
        }
        guard let deepLink = AppDeepLink(notification: link) else { return }
        router.apply(deepLink, selectedTab: &selectedTab)
    }

    /// 广场帖深链：独立 Tab 或软启动活动栈（单层栈，无嵌套 NavigationStack）。
    func openCommunityPost(_ id: CommunityPost.ID) {
        pendingCommunityPostID = id
        if productLifecycleStore.shouldMergeCommunityIntoActivitiesTab {
            selectedTab = .activities
        } else {
            selectedTab = .community
        }
    }

    /// 软启动：打开活动 Tab 内嵌广场 Feed（浏览入口，非单帖深链）。
    func openEmbeddedCommunityFeed() {
        guard productLifecycleStore.shouldMergeCommunityIntoActivitiesTab else {
            selectedTab = .community
            return
        }
        pendingOpenEmbeddedCommunityFeed = true
        selectedTab = .activities
    }
}
