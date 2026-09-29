//
//  SettingsNotificationsView.swift
//  坐标系
//
//  设置 · 通知偏好。
//

import SwiftUI
import UIKit
import CoordinateModels

struct SettingsNotificationsView: View {
    @Environment(NotificationPreferencesStore.self) private var notificationPrefs
    @State private var authStatusText = "读取中…"
    @State private var showDeniedHint = false

    var body: some View {
        @Bindable var notificationPrefs = notificationPrefs

        Form {
            Section {
                LabeledContent("系统通知权限", value: authStatusText)
                if showDeniedHint {
                    Button("打开系统设置") {
                        NotificationService.openSystemSettings()
                    }
                }
            }

            Section {
                Toggle("活动提醒", isOn: $notificationPrefs.activityReminders)
                    .onChange(of: notificationPrefs.activityReminders) { _, enabled in
                        if enabled { Task { await requestIfNeeded() } }
                    }
                Toggle("搭子上线通知", isOn: $notificationPrefs.buddyOnline)
                Toggle("新消息通知", isOn: $notificationPrefs.messagePush)
                Toggle("社区精选摘要", isOn: $notificationPrefs.communityDigest)
            } header: {
                Text("推送偏好（本地）")
            } footer: {
                Text("开启活动提醒时会请求系统通知权限。搭子上线与社区摘要为本地偏好占位，正式版将接运营推送。")
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .task { await refreshStatus() }
    }

    private func requestIfNeeded() async {
        let granted = await NotificationService.requestAuthorization()
        await refreshStatus()
        showDeniedHint = !granted
    }

    private func refreshStatus() async {
        let status = await NotificationService.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            authStatusText = "已允许"
            showDeniedHint = false
        case .denied:
            authStatusText = "已拒绝"
            showDeniedHint = true
        case .notDetermined:
            authStatusText = "未请求"
            showDeniedHint = false
        @unknown default:
            authStatusText = "未知"
        }
    }
}

