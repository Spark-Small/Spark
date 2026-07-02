// Module: SparkActivity — APNs permission + registration (Phase 16).

import SparkCore
import UIKit
import UserNotifications

public enum ActivityNotificationRegistrar {
    public static func registerIfNeeded() {
        guard ActivityNotificationPreferences.remindersEnabled else { return }
        Task { await requestAuthorizationIfNeeded() }
    }

    @MainActor
    private static func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        let source = SparkPermissionTelemetry.Source.activityRemindersToggle
        SparkPermissionTelemetry.statusChecked(
            permission: .notifications,
            source: source,
            status: SparkPermissionTelemetry.notificationStatus(from: settings.authorizationStatus)
        )

        switch settings.authorizationStatus {
        case .notDetermined:
            SparkPermissionTelemetry.promptRequested(permission: .notifications, source: source)
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            SparkPermissionTelemetry.promptResult(
                permission: .notifications,
                source: source,
                outcome: SparkPermissionTelemetry.notificationOutcome(granted: granted)
            )
            if granted {
                registerRemoteIfNeeded()
            }
        case .authorized, .provisional, .ephemeral:
            registerRemoteIfNeeded()
        case .denied:
            break
        @unknown default:
            break
        }
    }

    @MainActor
    private static func registerRemoteIfNeeded() {
        // REASONING: Remote push requires paid team + aps-environment; local reminders work without it.
        #if SPARK_ENABLE_PUSH
        UIApplication.shared.registerForRemoteNotifications()
        #endif
    }
}
