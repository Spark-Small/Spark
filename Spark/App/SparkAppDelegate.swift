// Module: Spark — Push tap → activity detail (Phase 16).

import SparkAppShell
import SparkAuth
import SparkPayments
import UIKit
import UserNotifications

final class SparkAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    weak var router: AppRouter?
    weak var authViewModel: AuthViewModel?
    var deviceTokenUploader: (any DeviceTokenUploading)?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        CompositionRoot.bootstrapIfNeeded()
        if authViewModel?.handleOpenURL(url) == true { return true }
        return CompositionRoot.dependencies.entitlementManager.handleOpenURL(url)
    }

    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        CompositionRoot.bootstrapIfNeeded()
        if authViewModel?.handleOpenURL(url) == true { return true }
        return CompositionRoot.dependencies.entitlementManager.handleOpenURL(url)
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
        } else if let likesPayload = LikesPushPayload.parse(userInfo: response.notification.request.content.userInfo) {
            Task { @MainActor in
                switch likesPayload.kind {
                case .inbound:
                    router?.openLikesInbound()
                case .match(let threadID):
                    if let threadID {
                        router?.openConversation(threadID: threadID)
                    } else {
                        router?.openLikesInbound()
                    }
                }
            }
        } else if let communityPayload = CommunityPushPayload.parse(userInfo: response.notification.request.content.userInfo) {
            Task { @MainActor in
                router?.openCommunityPost(postID: communityPayload.postID)
            }
        } else if let messagesPayload = MessagesPushPayload.parse(userInfo: response.notification.request.content.userInfo) {
            Task { @MainActor in
                router?.openConversation(threadID: messagesPayload.threadID)
            }
        }
        completionHandler()
    }
}
