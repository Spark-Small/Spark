//
//  ProfileSettingsMoreViews.swift
//  坐标系
//
//  设置子页：公告 / 致谢 / 青少年模式。
//

import CoordinateModels
import SwiftUI

struct SettingsAnnouncementsView: View {
    @Environment(OpsContentStore.self) private var store

    var body: some View {
        Group {
            if store.announcements.isEmpty {
                ProfileLibraryEmptyView(
                    title: "暂无公告",
                    systemImage: "megaphone",
                    description: "运营公告会在此出现。"
                )
            } else {
                List {
                    Section {
                        ForEach(store.announcements.sorted {
                            if $0.pin != $1.pin { return $0.pin && !$1.pin }
                            return $0.publishedAt > $1.publishedAt
                        }) { item in
                            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                HStack {
                                    Text(item.title)
                                        .font(.body.weight(.semibold))
                                    if item.pin {
                                        Text("置顶")
                                            .font(.caption2.weight(.semibold))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                Text(item.body)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(Formatters.conversationListTime(from: item.publishedAt))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .swipeActions(edge: .trailing) {
                                Button("标为已读") {
                                    store.dismissAnnouncement(item.id)
                                }
                            }
                        }
                    } footer: {
                        Text("左右滑动可标为已读。正式版将支持定向推送与活动运营位。")
                    }
                }
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle("运营公告")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - Acknowledgments

struct SettingsAcknowledgmentsView: View {
    var body: some View {
        Form {
            Section("声明") {
                Text("坐标系当前为本地演示构建，未嵌入第三方广告或统计分析 SDK。系统框架（SwiftUI、UserNotifications、PassKit 等）遵循 Apple 许可。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Section("设计参考") {
                Text("交互与信息架构借鉴成熟社交与本地生活产品的常见设置 / 合规分区，文案与流程已按本产品场景改写。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("开源与致谢")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}

// MARK: - Youth mode

struct SettingsYouthModeView: View {
    @Environment(YouthModeStore.self) private var youthMode

    var body: some View {
        @Bindable var youthMode = youthMode

        Form {
            Section {
                Toggle("开启青少年模式", isOn: $youthMode.isEnabled)
            } footer: {
                Text("开启后将限制会员开通与钱包充值入口（本地演示）。正式版将支持监护人验证与时段限制。")
            }
            if youthMode.isEnabled {
                Section("当前限制") {
                    Label("不可开通会员", systemImage: "checkmark.seal")
                    Label("不可钱包充值与付费预约", systemImage: "creditcard")
                    Label("仍可浏览活动与社区", systemImage: "eye")
                }
                .platformContentSymbolStyle()
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("青少年模式")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
    }
}
