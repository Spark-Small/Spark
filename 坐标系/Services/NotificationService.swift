//
//  NotificationService.swift
//  坐标系
//

import Foundation
import UIKit
import UserNotifications

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
