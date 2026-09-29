//
//  NotificationService.swift
//  坐标系
//

import Foundation
import UIKit
import UserNotifications
import CoordinateDomain
import CoordinateModels

@MainActor
enum NotificationService {
    enum PreferenceKey {
        static let activity = "settings.notify.activity"
        static let buddy = "settings.notify.buddy"
        static let message = "settings.notify.message"
        static let community = "settings.notify.community"
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    static func isActivityRemindersEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: PreferenceKey.activity) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PreferenceKey.activity)
    }

    /// 活动开始前 1 小时本地提醒
    static func scheduleActivityReminder(activityID: UUID, title: String, at date: Date) {
        guard isActivityRemindersEnabled() else { return }
        let fire = date.addingTimeInterval(-3600)
        guard fire > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "活动即将开始"
        content.body = "「\(title)」约 1 小时后开始，别迟到哦"
        content.sound = .default
        content.userInfo = [
            "activityID": activityID.uuidString,
            "kind": "activity-reminder"
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fire
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "activity-\(activityID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelActivityReminder(activityID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["activity-\(activityID.uuidString)"])
    }

    /// 活动本地生命周期结束后提醒写复盘 / 反馈
    static func scheduleActivityRecapReminder(activityID: UUID, title: String, activityStart: Date) {
        guard isActivityRemindersEnabled() else { return }
        let fire = activityStart.addingTimeInterval(ActivityLifecycle.ongoingGrace)
        guard fire > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "玩得怎么样？"
        content.body = "「\(title)」已结束，分享你的感受吧"
        content.sound = .default
        content.userInfo = [
            "activityID": activityID.uuidString,
            "kind": "activity-recap"
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fire
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "activity-recap-\(activityID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelActivityRecapReminder(activityID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["activity-recap-\(activityID.uuidString)"])
    }

    /// 候补名额开放时提醒用户可转正参加
    static func scheduleWaitlistSpotAvailable(activityID: UUID, title: String) {
        guard isActivityRemindersEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "候补名额已开放"
        content.body = "「\(title)」有空位了，快去转正参加"
        content.sound = .default
        content.userInfo = ["activityID": activityID.uuidString, "kind": "waitlist-spot"]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "waitlist-spot-\(activityID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelWaitlistSpotNotification(activityID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["waitlist-spot-\(activityID.uuidString)"])
    }

    static func scheduleBookingReminder(bookingID: UUID, companion: String, at date: Date) {
        guard isActivityRemindersEnabled() else { return }
        let fire = date.addingTimeInterval(-1800)
        guard fire > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "陪玩预约提醒"
        content.body = "与 \(companion) 的预约约 30 分钟后开始"
        content.sound = .default
        content.userInfo = [
            "bookingID": bookingID.uuidString,
            "kind": "booking-reminder"
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fire
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking-\(bookingID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelBookingReminder(bookingID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["booking-\(bookingID.uuidString)"])
    }

    /// B-31：陪玩已接单，提醒用户去支付（尊重「搭子在线」类通知开关）。
    static func scheduleBookingAcceptedNotification(bookingID: UUID, companion: String) {
        guard isBuddyOnlineEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(companion) 已接单"
        content.body = "请核对订单并完成支付，超时未付将自动释放。"
        content.sound = .default
        content.userInfo = [
            "bookingID": bookingID.uuidString,
            "kind": "booking-accepted"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking-accepted-\(bookingID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// B-30：在确认 SLA 截止时提醒（若仍未接单，打开 App 后会自动取消）。
    static func scheduleBookingConfirmationSLA(
        bookingID: UUID,
        companion: String,
        confirmDueAt: Date
    ) {
        guard isBuddyOnlineEnabled() else { return }
        guard confirmDueAt > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = "仍在等待 \(companion) 确认"
        content.body = "若仍未确认，预约可能已超时取消，请打开查看订单。"
        content.sound = .default
        content.userInfo = [
            "bookingID": bookingID.uuidString,
            "kind": "booking-confirm-sla"
        ]

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: confirmDueAt
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking-confirm-sla-\(bookingID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func cancelBookingConfirmationNotifications(bookingID: UUID) {
        let id = bookingID.uuidString
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [
                "booking-confirm-sla-\(id)",
                "booking-accepted-\(id)"
            ]
        )
    }

    /// 确认 SLA 超时后本地提醒（订单已在 App 内取消时补发）。
    static func scheduleBookingConfirmationExpiredNotification(
        bookingID: UUID,
        companion: String
    ) {
        guard isBuddyOnlineEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "预约确认超时"
        content.body = "\(companion) 未在时限内确认，预约已自动取消。"
        content.sound = .default
        content.userInfo = [
            "bookingID": bookingID.uuidString,
            "kind": "booking-confirm-expired"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking-confirm-expired-\(bookingID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// 陪玩退款到账后本地提醒（B-45）。
    static func scheduleBookingRefundCompletedNotification(
        bookingID: UUID,
        companion: String,
        amountDisplay: String
    ) {
        guard isBuddyOnlineEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = "退款已完成"
        content.body = "陪玩预约「\(companion)」已退回 \(amountDisplay)"
        content.sound = .default
        content.userInfo = [
            "bookingID": bookingID.uuidString,
            "kind": "booking-refund"
        ]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "booking-refund-\(bookingID.uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    static func isMessagePushEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: PreferenceKey.message) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PreferenceKey.message)
    }

    static func isBuddyOnlineEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: PreferenceKey.buddy) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PreferenceKey.buddy)
    }

    static func isCommunityDigestEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: PreferenceKey.community) == nil {
            return false
        }
        return UserDefaults.standard.bool(forKey: PreferenceKey.community)
    }

    /// 新消息本地通知（尊重「新消息通知」开关；免打扰由调用方跳过）
    static func scheduleMessageNotification(conversationID: UUID, title: String, body: String) {
        guard isMessagePushEnabled() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["conversationID": conversationID.uuidString]

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.35, repeats: false)
        let request = UNNotificationRequest(
            identifier: "message-\(conversationID.uuidString)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
