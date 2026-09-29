//
//  SettingsPrivacyView.swift
//  坐标系
//
//  设置 · 隐私偏好。
//

import SwiftUI
import UIKit
import CoordinateModels

struct SettingsPrivacyView: View {
    @Environment(PrivacyPreferencesStore.self) private var privacyPrefs

    var body: some View {
        @Bindable var privacyPrefs = privacyPrefs

        Form {
            Section {
                Toggle("展示大致距离", isOn: $privacyPrefs.showDistance)
                Toggle("展示在线状态", isOn: $privacyPrefs.showOnline)
                Toggle("允许陌生人邀约", isOn: $privacyPrefs.allowInvite)
            } header: {
                Text("资料可见性")
            } footer: {
                Text("距离与在线影响搭子卡 / 详情展示；「允许陌生人邀约」会记入信任中心，正式版用于拦截入站邀约。")
            }
        }
        .navigationTitle("隐私")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

