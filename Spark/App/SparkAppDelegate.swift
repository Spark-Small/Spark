// Module: Spark — Push tap → activity detail (Phase 16).

import SparkAppShell
import UIKit
import UserNotifications

final class SparkAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var router: AppRouter?
    var deviceTokenUploader: (any DeviceTokenUploading)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let uploader = deviceTokenUploader
        Task {
            await uploader?.upload(apnsToken: deviceToken)
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if let payload = ActivityPushPayload.parse(userInfo: response.notification.request.content.userInfo) {
            Task { @MainActor in
                router?.openActivityDetail(activityID: payload.activityID)
            }
        }
        completionHandler()
    }
}
