// Module: SparkNotifications — UserDefaults-backed notification category toggles.

import Foundation

public enum SparkNotificationPreferences: Sendable {
    private static let matchEnabledKey = "spark.notifications.match.enabled"
    private static let messageEnabledKey = "spark.notifications.message.enabled"
    private static let activityEnabledKey = "spark.notifications.activity.enabled"

    public static var matchEnabled: Bool {
        get { bool(forKey: matchEnabledKey, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: matchEnabledKey) }
    }

    public static var messageEnabled: Bool {
        get { bool(forKey: messageEnabledKey, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: messageEnabledKey) }
    }

    public static var activityEnabled: Bool {
        get { bool(forKey: activityEnabledKey, defaultValue: true) }
        set { UserDefaults.standard.set(newValue, forKey: activityEnabledKey) }
    }

    private static func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil {
            return defaultValue
        }
        return UserDefaults.standard.bool(forKey: key)
    }
}
