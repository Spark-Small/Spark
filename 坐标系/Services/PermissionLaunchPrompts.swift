//
//  PermissionLaunchPrompts.swift
//  坐标系
//
//  系统权限弹窗：通知在报名成功时请求；跟踪仅在设置页主动触发。
//

import AppTrackingTransparency
import Foundation
import UserNotifications
import CoordinateModels

@MainActor
enum PermissionLaunchPrompts {
    private static let didAskTrackingKey = "compliance.didAskTrackingAuthorization"
    private static let didAskNotificationKey = "compliance.didAskNotificationAuthorization"

    private static var trackingTask: Task<Void, Never>?
    private static var notificationTask: Task<Void, Never>?

    static func reset() {
        UserDefaults.standard.removeObject(forKey: didAskTrackingKey)
        UserDefaults.standard.removeObject(forKey: didAskNotificationKey)
    }

    /// 设置页等主动入口：请求 ATT（不在开屏 / 登录链触发）。
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

    private static func performTrackingRequest() async {
        guard !UserDefaults.standard.bool(forKey: didAskTrackingKey) else { return }

        let status = ATTrackingManager.trackingAuthorizationStatus
        guard status == .notDetermined else {
            UserDefaults.standard.set(true, forKey: didAskTrackingKey)
            return
        }

        UserDefaults.standard.set(true, forKey: didAskTrackingKey)
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    /// 首次报名成功：请求通知权限（动机最强）。
    static func requestNotificationWhenJoiningIfNeeded() async {
        await requestNotificationAfterEnterHomeIfNeeded()
    }

    /// 请求「发送通知」（系统通知权限 Alert）。
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

        UserDefaults.standard.set(true, forKey: didAskNotificationKey)
        _ = await NotificationService.requestAuthorization()
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
