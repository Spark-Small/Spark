//
//  AppNotificationRouter.swift
//  坐标系
//
//  本地通知点击 → 深链进对应活动 / 会话 / 预约。
//

import Foundation
import UserNotifications
import CoordinateModels

enum NotificationDeepLink: Equatable {
    case activity(UUID, followUp: ActivityNotificationFollowUp = .none)
    case booking(UUID)
    case conversation(UUID)
    case communityPost(UUID)

    static func parse(
        userInfo: [AnyHashable: Any],
        identifier: String
    ) -> NotificationDeepLink? {
        if let id = uuid(from: userInfo["communityPostID"]) {
            return .communityPost(id)
        }
        if let id = uuid(from: userInfo["activityID"]) {
            let kind = userInfo["kind"] as? String
            let followUp: ActivityNotificationFollowUp = switch kind {
            case "activity-recap": .journeyFeedback
            case "activity-reminder": .openJourney
            case "waitlist-spot": .none
            default: .none
            }
            return .activity(id, followUp: followUp)
        }
        if let id = uuid(from: userInfo["conversationID"]) {
            return .conversation(id)
        }
        if let id = uuid(from: userInfo["bookingID"]) {
            return .booking(id)
        }

        if identifier.hasPrefix("activity-recap-"),
           let id = uuidSuffix(identifier, prefixes: ["activity-recap-"]) {
            return .activity(id, followUp: .journeyFeedback)
        }
        if identifier.hasPrefix("activity-"),
           !identifier.hasPrefix("activity-recap-"),
           let id = uuidSuffix(identifier, prefixes: ["activity-"]) {
            return .activity(id, followUp: .openJourney)
        }
        if let id = uuidSuffix(identifier, prefixes: ["waitlist-spot-"]) {
            return .activity(id)
        }
        if let id = uuidSuffix(identifier, prefixes: ["booking-refund-", "booking-accepted-", "booking-confirm-sla-", "booking-confirm-expired-", "booking-"]) {
            return .booking(id)
        }
        // community-like-{postID}-… / community-repost-… / community-comment-…
        if identifier.hasPrefix("community-"),
           let postID = communityPostID(fromDedupeKey: identifier) {
            return .communityPost(postID)
        }
        return nil
    }

    /// `community-{kind}-{uuid}-{actor}` → uuid
    private static func communityPostID(fromDedupeKey identifier: String) -> UUID? {
        let parts = identifier.split(separator: "-", omittingEmptySubsequences: false)
        // community, kind, 8-4-4-4-12 uuid parts…
        guard parts.count >= 7, parts[0] == "community" else { return nil }
        let uuidString = parts[2..<7].joined(separator: "-")
        return UUID(uuidString: uuidString)
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

    // 前台也展示横幅，并写入站内通知中心
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let request = notification.request
        AppComposition.inAppNotificationStore.ingestSystemNotification(
            identifier: request.identifier,
            title: request.content.title,
            body: request.content.body,
            userInfo: request.content.userInfo,
            deliveredAt: notification.date
        )
        return [.banner, .sound, .list]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let request = response.notification.request
        AppComposition.inAppNotificationStore.ingestSystemNotification(
            identifier: request.identifier,
            title: request.content.title,
            body: request.content.body,
            userInfo: request.content.userInfo,
            deliveredAt: response.notification.date
        )
        AppComposition.inAppNotificationStore.markReadMatching(dedupeKey: request.identifier)
        guard let link = NotificationDeepLink.parse(
            userInfo: request.content.userInfo,
            identifier: request.identifier
        ) else { return }
        route(link)
    }
}
