//
//  SettingsAboutView.swift
//  坐标系
//
//  设置 · 关于。
//

import SwiftUI
import UIKit
import CoordinateModels

struct SettingsAboutView: View {
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @State private var updateMessage: String?

    private var version: String {
        lifecycle.versionLabel
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("版本", value: version)
                LabeledContent("产品", value: "坐标系")
                Button("检查更新") {
                    updateMessage = "已是最新版本 \(version)"
                }
            }
            Section("说明") {
                Text("坐标系帮你发现活动、找到搭子，并把社区分享与消息串成一条闭环。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Section("合规") {
                NavigationLink("用户协议") { UserAgreementView().toolbarVisibility(.hidden, for: .tabBar) }
                NavigationLink("隐私政策") { PrivacyPolicyView().toolbarVisibility(.hidden, for: .tabBar) }
                NavigationLink("社区公约") { CommunityGuidelinesView().toolbarVisibility(.hidden, for: .tabBar) }
            }
            Section {
                NavigationLink("开源与致谢") { SettingsAcknowledgmentsView() }
            }
            #if DEBUG
            Section("产品观察（本地）") {
                LabeledContent("安装天数", value: "\(lifecycle.daysSinceInstall)")
                LabeledContent("广场 7 日打开", value: "\(lifecycle.tabVisitCount(.community))")
                if lifecycle.shouldReviewCommunityTabPlacement {
                    Text("建议评估广场 Tab 位置（安装 ≥7 天且广场 7 日内零打开）")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            #endif
        }
        .navigationTitle("关于坐标系")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("检查更新", isPresented: Binding(
            get: { updateMessage != nil },
            set: { if !$0 { updateMessage = nil } }
        )) {
            Button("好的", role: .cancel) { updateMessage = nil }
        } message: {
            Text(updateMessage ?? "")
        }
    }
}

