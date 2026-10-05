//
//  InAppNotificationStore.swift
//  坐标系
//
//  站内通知中心：与 UNUserNotification 深链对齐的本地收件箱（Apple 推荐的
//  系统推送 + 应用内历史列表双轨）。
//

import Foundation
import Observation
import UserNotifications
import CoordinateModels

enum InAppNotificationCategory: String, Codable, CaseIterable, Hashable, Sendable {
    case activity
    case buddy
    case message
    case community
    case system

    var title: String {
        switch self {
        case .activity: "活动"
        case .buddy: "搭子"
        case .message: "消息"
        case .community: "广场"
        case .system: "系统"
        }
    }

    var systemImage: String {
        switch self {
        case .activity: "calendar"
        case .buddy: "person.2"
        case .message: "bubble.left.and.bubble.right"
        case .community: "photo.on.rectangle"
        case .system: "gearshape"
        }
    }
}

struct InAppNotificationItem: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    var category: InAppNotificationCategory
    var title: String
    var body: String
    var createdAt: Date
    var isRead: Bool
    /// 与 `UNNotificationRequest.identifier` 对齐，避免重复入库。
    var dedupeKey: String?
    var activityID: UUID?
    var bookingID: UUID?
    var conversationID: UUID?
    /// 广场帖深链（赞/评/转通知）。
    var communityPostID: UUID?
    var activityKind: String?

    init(
        id: UUID = UUID(),
        category: InAppNotificationCategory,
        title: String,
        body: String,
        createdAt: Date = .now,
        isRead: Bool = false,
        dedupeKey: String? = nil,
        activityID: UUID? = nil,
        bookingID: UUID? = nil,
        conversationID: UUID? = nil,
        communityPostID: UUID? = nil,
        activityKind: String? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
        self.dedupeKey = dedupeKey
        self.activityID = activityID
        self.bookingID = bookingID
        self.conversationID = conversationID
        self.communityPostID = communityPostID
        self.activityKind = activityKind
    }

    var deepLink: NotificationDeepLink? {
        if let communityPostID {
            return .communityPost(communityPostID)
        }
        if let kind = activityKind, kind.hasPrefix("activity-invite") {
            if kind == "activity-invite-accepted", let activityID {
                return .activity(activityID, followUp: .none)
            }
            return .activityInvites
        }
        if let activityID {
            let followUp: ActivityNotificationFollowUp = switch activityKind {
            case "activity-recap": .journeyFeedback
            case "activity-reminder": .openJourney
            default: .none
            }
            return .activity(activityID, followUp: followUp)
        }
        if let bookingID {
            return .booking(bookingID)
        }
        if let conversationID {
            return .conversation(conversationID)
        }
        return nil
    }
}

@MainActor
@Observable
final class InAppNotificationStore {
    static var shared: InAppNotificationStore { AppComposition.inAppNotificationStore }

    private enum Key {
        static let items = "notifications.inbox.items"
        static let maxItems = 200
    }

    private(set) var items: [InAppNotificationItem] = []
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        items = Self.load(from: defaults)
    }

    var unreadCount: Int {
        items.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
    }

    var hasUnread: Bool { unreadCount > 0 }

    func items(in category: InAppNotificationCategory?) -> [InAppNotificationItem] {
        let filtered: [InAppNotificationItem]
        if let category {
            filtered = items.filter { $0.category == category }
        } else {
            filtered = items
        }
        return filtered.sorted { $0.createdAt > $1.createdAt }
    }

    /// 从系统通知内容写入站内收件箱（前台横幅 / 点击 / 已投递同步共用）。
    @discardableResult
    func ingestSystemNotification(
        identifier: String,
        title: String,
        body: String,
        userInfo: [AnyHashable: Any],
        deliveredAt: Date = .now
    ) -> InAppNotificationItem? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty || !trimmedBody.isEmpty else { return nil }

        if let existingIndex = items.firstIndex(where: { $0.dedupeKey == identifier }) {
            var existing = items[existingIndex]
            existing.title = trimmedTitle.isEmpty ? existing.title : trimmedTitle
            existing.body = trimmedBody.isEmpty ? existing.body : trimmedBody
            existing.createdAt = max(existing.createdAt, deliveredAt)
            items[existingIndex] = existing
            persist()
            return existing
        }

        let activityID = Self.uuid(from: userInfo["activityID"])
        let bookingID = Self.uuid(from: userInfo["bookingID"])
        let conversationID = Self.uuid(from: userInfo["conversationID"])
        let kind = userInfo["kind"] as? String
        let category = Self.category(
            identifier: identifier,
            kind: kind,
            hasActivity: activityID != nil,
            hasBooking: bookingID != nil,
            hasConversation: conversationID != nil
        )

        let item = InAppNotificationItem(
            category: category,
            title: trimmedTitle.isEmpty ? category.title : trimmedTitle,
            body: trimmedBody,
            createdAt: deliveredAt,
            isRead: false,
            dedupeKey: identifier,
            activityID: activityID,
            bookingID: bookingID,
            conversationID: conversationID,
            activityKind: kind
        )
        prepend(item)
        return item
    }

    func record(
        category: InAppNotificationCategory,
        title: String,
        body: String,
        dedupeKey: String? = nil,
        activityID: UUID? = nil,
        bookingID: UUID? = nil,
        conversationID: UUID? = nil,
        communityPostID: UUID? = nil,
        activityKind: String? = nil
    ) {
        if let dedupeKey,
           items.contains(where: { $0.dedupeKey == dedupeKey }) {
            return
        }
        prepend(
            InAppNotificationItem(
                category: category,
                title: title,
                body: body,
                dedupeKey: dedupeKey,
                activityID: activityID,
                bookingID: bookingID,
                conversationID: conversationID,
                communityPostID: communityPostID,
                activityKind: activityKind
            )
        )
    }

    func markRead(_ id: InAppNotificationItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        guard !items[index].isRead else { return }
        items[index].isRead = true
        persist()
        syncApplicationBadge()
    }

    func markReadMatching(dedupeKey: String) {
        guard let index = items.firstIndex(where: { $0.dedupeKey == dedupeKey }) else { return }
        guard !items[index].isRead else { return }
        items[index].isRead = true
        persist()
        syncApplicationBadge()
    }

    func markAllRead() {
        guard items.contains(where: { !$0.isRead }) else { return }
        for index in items.indices {
            items[index].isRead = true
        }
        persist()
        syncApplicationBadge()
    }

    func remove(_ id: InAppNotificationItem.ID) {
        items.removeAll { $0.id == id }
        persist()
        syncApplicationBadge()
    }

    /// 取消赞 / 取消转发等：按 dedupeKey 撤销对应站内通知。
    func removeMatching(dedupeKey: String) {
        let before = items.count
        items.removeAll { $0.dedupeKey == dedupeKey }
        guard items.count != before else { return }
        persist()
        syncApplicationBadge()
    }

    /// 删帖：清掉指向该帖的全部社区通知。
    func removeCommunityItems(forPostID postID: UUID) {
        let before = items.count
        items.removeAll { $0.communityPostID == postID }
        guard items.count != before else { return }
        persist()
        syncApplicationBadge()
    }

    /// 拉黑后从预览 / 通知中心去掉标题或正文点名该用户的社区条目。
    func removeItemsMentioning(displayName: String) {
        let needle = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return }
        let before = items.count
        items.removeAll { item in
            item.category == .community
                && (
                    item.title.localizedCaseInsensitiveContains(needle)
                        || item.body.localizedCaseInsensitiveContains(needle)
                )
        }
        guard items.count != before else { return }
        persist()
        syncApplicationBadge()
    }

    func removeAll() {
        guard !items.isEmpty else { return }
        items = []
        persist()
        syncApplicationBadge()
    }

    /// 把系统通知中心已投递条目同步进站内列表（冷启动 / 打开收件箱时）。
    func syncDeliveredFromSystem() async {
        let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
        guard !delivered.isEmpty else {
            syncApplicationBadge()
            return
        }
        for notification in delivered {
            let request = notification.request
            _ = ingestSystemNotification(
                identifier: request.identifier,
                title: request.content.title,
                body: request.content.body,
                userInfo: request.content.userInfo,
                deliveredAt: notification.date
            )
        }
        syncApplicationBadge()
    }

    func resetAll() {
        items = []
        defaults.removeObject(forKey: Key.items)
        syncApplicationBadge()
    }

    func syncApplicationBadge() {
        let count = unreadCount
        UNUserNotificationCenter.current().setBadgeCount(count)
    }

    // MARK: - Private

    private func prepend(_ item: InAppNotificationItem) {
        items.insert(item, at: 0)
        if items.count > Key.maxItems {
            items = Array(items.prefix(Key.maxItems))
        }
        persist()
        syncApplicationBadge()
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        defaults.set(data, forKey: Key.items)
    }

    private static func load(from defaults: UserDefaults) -> [InAppNotificationItem] {
        guard let data = defaults.data(forKey: Key.items),
              let decoded = try? JSONDecoder().decode([InAppNotificationItem].self, from: data)
        else {
            return []
        }
        return decoded.sorted { $0.createdAt > $1.createdAt }
    }

    private static func uuid(from value: Any?) -> UUID? {
        guard let raw = value as? String else { return nil }
        return UUID(uuidString: raw)
    }

    private static func category(
        identifier: String,
        kind: String?,
        hasActivity: Bool,
        hasBooking: Bool,
        hasConversation: Bool
    ) -> InAppNotificationCategory {
        if hasConversation || identifier.hasPrefix("message-") {
            return .message
        }
        if hasBooking || identifier.hasPrefix("booking-") {
            return .buddy
        }
        if hasActivity
            || identifier.hasPrefix("activity-")
            || identifier.hasPrefix("waitlist-spot-")
            || kind == "activity-reminder"
            || kind == "activity-recap"
            || kind == "waitlist-spot"
        {
            return .activity
        }
        if kind == "community" || identifier.hasPrefix("community-") {
            return .community
        }
        return .system
    }
}
