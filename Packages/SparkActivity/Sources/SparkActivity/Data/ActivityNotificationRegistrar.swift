// Module: SparkActivity — APNs permission + registration (Phase 16).

import UIKit
import UserNotifications

public enum ActivityNotificationRegistrar {
    public static func registerIfNeeded() {
        guard ActivityNotificationPreferences.remindersEnabled else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            // REASONING: Remote push requires paid team + aps-environment; local reminders work without it.
            #if SPARK_ENABLE_PUSH
            Task { @MainActor in
                UIApplication.shared.registerForRemoteNotifications()
            }
            #endif
        }
    }
}
