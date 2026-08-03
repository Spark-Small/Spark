//
//  PermissionLaunchPrompts.swift
//  坐标系
//
//  协议同意后的系统权限弹窗：跟踪（登录页）→ 通知（进入主界面）。
//  仅调用系统 API，文案由 iOS / Info.plist 提供。
//

import AppTrackingTransparency
import Foundation
import UserNotifications

@MainActor
enum PermissionLaunchPrompts {
    private static let didAskTrackingKey = "compliance.didAskTrackingAuthorization"
    private static let didAskNotificationKey = "compliance.didAskNotificationAuthorization"

    static func reset() {
        UserDefaults.standard.removeObject(forKey: didAskTrackingKey)
        UserDefaults.standard.removeObject(forKey: didAskNotificationKey)
    }

    /// 登录页：隐私同意后请求「允许跟踪」（系统 ATT Alert）。
    static func requestTrackingAfterConsentIfNeeded() async {
        guard LegalConsentPreference.isAccepted else { return }
        guard !UserDefaults.standard.bool(forKey: didAskTrackingKey) else { return }

        if let inflight = trackingTask {
            await inflight.value
            return
        }

        let task = Task { @MainActor in
            await performTrackingRequest()
        }
        trackingTask = task
        await task.value
        trackingTask = nil
    }

    private static var trackingTask: Task<Void, Never>?
    private static var notificationTask: Task<Void, Never>?

    private static func performTrackingRequest() async {
        guard !UserDefaults.standard.bool(forKey: didAskTrackingKey) else { return }

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            UserDefaults.standard.set(true, forKey: didAskTrackingKey)
            return
        }

        // 等协议 Alert 收起后再弹，避免叠层。
        try? await Task.sleep(for: .milliseconds(700))
        guard !Task.isCancelled else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
            UserDefaults.standard.set(true, forKey: didAskTrackingKey)
            return
        }

        UserDefaults.standard.set(true, forKey: didAskTrackingKey)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// 主界面：请求「发送通知」（系统通知权限 Alert）。
    static func requestNotificationAfterEnterHomeIfNeeded() async {
        guard LegalConsentPreference.isAccepted else { return }
        guard !UserDefaults.standard.bool(forKey: didAskNotificationKey) else { return }

        if let inflight = notificationTask {
            await inflight.value
            return
        }

        let task = Task { @MainActor in
            await performNotificationRequest()
        }
        notificationTask = task
        await task.value
        notificationTask = nil
    }

    private static func performNotificationRequest() async {
        guard !UserDefaults.standard.bool(forKey: didAskNotificationKey) else { return }

        let status = await NotificationService.authorizationStatus()
        guard status == .notDetermined else {
            UserDefaults.standard.set(true, forKey: didAskNotificationKey)
            return
        }

        try? await Task.sleep(for: .milliseconds(900))
        guard !Task.isCancelled else { return }
        let latest = await NotificationService.authorizationStatus()
        guard latest == .notDetermined else {
            UserDefaults.standard.set(true, forKey: didAskNotificationKey)
            return
        }

        UserDefaults.standard.set(true, forKey: didAskNotificationKey)
        _ = await NotificationService.requestAuthorization()
    }

    /// 已登录冷启动进主页：若登录页未走过跟踪，则先跟踪再通知。
    static func requestPostLoginChainIfNeeded() async {
        guard LegalConsentPreference.isAccepted else { return }
        await requestTrackingAfterConsentIfNeeded()
        await requestNotificationAfterEnterHomeIfNeeded()
    }

    static var trackingStatusText: String {
        switch ATTrackingManager.trackingAuthorizationStatus {
        case .authorized: "已允许"
        case .denied, .restricted: "已拒绝"
        case .notDetermined: "未请求"
        @unknown default: "未知"
        }
    }
}
