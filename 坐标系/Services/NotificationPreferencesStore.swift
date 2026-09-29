//
//  NotificationPreferencesStore.swift
//  坐标系
//
//  通知偏好：设置页写入，NotificationService 读取同一 UserDefaults 键。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class NotificationPreferencesStore {
    static var shared: NotificationPreferencesStore { AppComposition.notificationPreferencesStore }

    var activityReminders: Bool {
        didSet { defaults.set(activityReminders, forKey: NotificationService.PreferenceKey.activity) }
    }

    var buddyOnline: Bool {
        didSet { defaults.set(buddyOnline, forKey: NotificationService.PreferenceKey.buddy) }
    }

    var messagePush: Bool {
        didSet { defaults.set(messagePush, forKey: NotificationService.PreferenceKey.message) }
    }

    var communityDigest: Bool {
        didSet { defaults.set(communityDigest, forKey: NotificationService.PreferenceKey.community) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        activityReminders = NotificationService.isActivityRemindersEnabled()
        buddyOnline = NotificationService.isBuddyOnlineEnabled()
        messagePush = NotificationService.isMessagePushEnabled()
        communityDigest = NotificationService.isCommunityDigestEnabled()
    }
}
