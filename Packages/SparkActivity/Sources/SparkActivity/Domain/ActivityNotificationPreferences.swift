// Module: SparkActivity — Activity reminder toggle (Phase 16).

import Foundation

public enum ActivityNotificationPreferences {
    private static let remindersEnabledKey = "spark.activity.reminders.enabled"

    public static var remindersEnabled: Bool {
        get {
            // REASONING: HIG — request notification permission only after explicit user action.
            if UserDefaults.standard.object(forKey: remindersEnabledKey) == nil {
                return false
            }
            return UserDefaults.standard.bool(forKey: remindersEnabledKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: remindersEnabledKey)
        }
    }
}
