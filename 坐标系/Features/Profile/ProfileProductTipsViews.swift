//
//  ProfileProductTipsViews.swift
//  坐标系
//
//  产品生命周期 Tip 行 + 设置内「产品提示」页（与协议门闸拆分）。
//

import CoordinateModels
import SwiftUI

struct ProductLifecycleTipSectionContent: View {
    let tip: ProductLifecycleTip
    var onDismiss: () -> Void
    var onOpenSettings: (() -> Void)?

    var body: some View {
        Text(tip.detail)
            .foregroundStyle(.secondary)

        if tip.id == "privacy", let onOpenSettings {
            Button("去设置", action: onOpenSettings)
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
        }

        Button("关闭", role: .cancel, action: onDismiss)
            .buttonStyle(.plain)
            .foregroundStyle(.primary)
    }
}

struct SettingsProductTipsView: View {
    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @State private var showPrivacyFromTip = false

    private var tips: [ProductLifecycleTip] {
        let hasOrders = !ActivityPaymentStore.allOrders().isEmpty
            || !buddies.bookingRecords.isEmpty
        return lifecycle.eligibleTips(
            isGuest: false,
            profileComplete: ProfileCompletion.ratio(for: app.user) >= 0.8,
            hasOrders: hasOrders
        )
    }

    var body: some View {
        Group {
            if tips.isEmpty {
                ProfileLibraryEmptyView(
                    title: "暂无提示",
                    systemImage: "lightbulb",
                    description: "产品提示会在合适时机出现；关闭后仍可在此查看未读项。"
                )
            } else {
                tipsList
            }
        }
        .navigationTitle("产品提示")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showPrivacyFromTip) {
            SettingsPrivacyView()
        }
    }

    private var tipsList: some View {
        List {
            ForEach(tips) { tip in
                Section {
                    ProductLifecycleTipSectionContent(
                        tip: tip,
                        onDismiss: { lifecycle.dismissTip(tip.id) },
                        onOpenSettings: tip.id == "privacy" ? { showPrivacyFromTip = true } : nil
                    )
                } header: {
                    Label(tip.title, systemImage: tip.systemImage)
                        .platformContentSymbolStyle()
                }
            }
        }
        .profileSecondaryListChrome()
    }
}
