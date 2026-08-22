//
//  AppNotificationRouter.swift
//  坐标系
//
//  本地通知点击 → 深链进对应活动 / 会话 / 预约。
//

import Foundation
import UserNotifications

enum NotificationDeepLink: Equatable {
    case activity(UUID)
    case booking(UUID)
    case conversation(UUID)

    static func parse(
        userInfo: [AnyHashable: Any],
        identifier: String
    ) -> NotificationDeepLink? {
        if let id = uuid(from: userInfo["activityID"]) {
            return .activity(id)
        }
        if let id = uuid(from: userInfo["conversationID"]) {
            return .conversation(id)
        }
        if let id = uuid(from: userInfo["bookingID"]) {
            return .booking(id)
        }

        if let id = uuidSuffix(identifier, prefixes: ["waitlist-spot-", "activity-"]) {
            return .activity(id)
        }
        if let id = uuidSuffix(identifier, prefixes: ["booking-"]) {
            return .booking(id)
        }
        return nil
    }

    private static func uuid(from value: Any?) -> UUID? {
        guard let raw = value as? String else { return nil }
        return UUID(uuidString: raw)
    }

    private static func uuidSuffix(_ identifier: String, prefixes: [String]) -> UUID? {
        for prefix in prefixes where identifier.hasPrefix(prefix) {
            let raw = String(identifier.dropFirst(prefix.count))
            if let id = UUID(uuidString: raw) { return id }
        }
        return nil
    }
}

/// App 启动即挂上；`AppModel` 就绪后再 `bind`，冷启动点击不会丢。
@MainActor
final class AppNotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationRouter()

    private weak var app: AppModel?
    private var pending: NotificationDeepLink?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func bind(_ app: AppModel) {
        self.app = app
        flush()
    }

    func route(_ link: NotificationDeepLink) {
        if let app {
            app.handleNotificationDeepLink(link)
        } else {
            pending = link
        }
    }

    private func flush() {
        guard let app, let pending else { return }
        self.pending = nil
        app.handleNotificationDeepLink(pending)
    }

    // 前台也展示横幅，方便演示「即将开始」
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let request = response.notification.request
        guard let link = NotificationDeepLink.parse(
            userInfo: request.content.userInfo,
            identifier: request.identifier
        ) else { return }
        route(link)
    }
}
