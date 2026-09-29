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

    /// 通知 / 深链：切到活动 Tab 并打开详情
    func openActivity(_ id: Activity.ID) {
        router.apply(.activity(id), selectedTab: &selectedTab)
    }

    /// 通知：打开「我的 → 陪玩预约」（可定位到具体单）
    func openMyBookings(bookingID: BuddyBookingRecord.ID? = nil) {
        router.apply(.booking(bookingID), selectedTab: &selectedTab)
    }

    func openClubDiscover() {
        router.apply(.buddies(.clubDiscover), selectedTab: &selectedTab)
    }

    func handleNotificationDeepLink(_ link: NotificationDeepLink) {
        guard let deepLink = AppDeepLink(notification: link) else { return }
        router.apply(deepLink, selectedTab: &selectedTab)
    }
}
