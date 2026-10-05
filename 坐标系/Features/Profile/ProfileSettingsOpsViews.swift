//
//  ProfileSettingsOpsViews.swift
//  坐标系
//
//  设置子页：帮助反馈 / 权限 / 存储。
//

import CoordinateModels
import SwiftUI
import UIKit
import UserNotifications

struct SettingsHelpFeedbackView: View {
    @Environment(OpsContentStore.self) private var opsContent
    @State private var category = "体验建议"
    @State private var content = ""
    @State private var contact = ""
    @State private var didSubmit = false
    @State private var showError = false

    private let categories = ["体验建议", "功能故障", "支付与订单", "安全与举报", "其他"]

    var body: some View {
        Form {
            Section("常见问题") {
                DisclosureGroup("如何参加付费活动？") {
                    Text("在活动详情确认费用后完成支付；行程在「我的活动」，账单在「我的钱包」。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("陪玩预约如何退款？") {
                    Text("在陪玩凭证页点「申请退款」，填写原因与说明并确认；提交后可查看退款进度，到账后金额按原支付方式退回。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("如何管理隐私？") {
                    Text("设置 → 隐私，可关闭距离、在线展示与陌生人邀约偏好。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                DisclosureGroup("举报后多久处理？") {
                    Text("本机演示会生成举报工单；正式版由运营审核。可在设置 → 举报记录查看状态。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Picker("类型", selection: $category) {
                    ForEach(categories, id: \.self) { Text($0).tag($0) }
                }
                TextField("描述问题或建议", text: $content, axis: .vertical)
                    .platformFormTextInput(.report)
                TextField("联系方式（选填）", text: $contact)
                    .platformFormTextInput(.contact)
            } header: {
                Text("提交反馈")
            } footer: {
                Text("反馈保存在本机，便于演示运营闭环；正式版将同步客服工单。")
            }

            if !opsContent.feedback.isEmpty {
                Section("我提交过的") {
                    ForEach(opsContent.feedback.prefix(8)) { item in
                        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                            LabeledContent(item.category, value: item.status)
                            Text(item.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: item.createdAt))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .platformTextInputScrollChrome()
        .profileSecondaryListChrome()
        .navigationTitle("帮助与反馈")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("提交") {
                    if opsContent.submitFeedback(
                        category: category,
                        content: content,
                        contact: contact
                    ) {
                        content = ""
                        contact = ""
                        didSubmit = true
                    } else {
                        showError = true
                    }
                }
                .fontWeight(.semibold)
            }
        }
        .alert("已收到反馈", isPresented: $didSubmit) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("感谢你的建议，运营同学（演示）已记录。")
        }
        .alert("请写得更具体一些", isPresented: $showError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("反馈至少 4 个字，方便我们理解问题。")
        }
    }
}

// MARK: - Permissions

struct SettingsPermissionsView: View {
    @Environment(LocationService.self) private var location
    @State private var notificationStatus = "读取中…"
    @State private var locationStatus = "—"
    @State private var trackingStatus = "—"

    var body: some View {
        Form {
            Section {
                permissionRow(
                    title: "通知",
                    systemImage: "bell.badge",
                    status: notificationStatus,
                    detail: "活动提醒、预约与消息"
                )
                permissionRow(
                    title: "跟踪",
                    systemImage: "hand.raised.fill",
                    status: trackingStatus,
                    detail: "个性化推荐与内容体验"
                )
                permissionRow(
                    title: "定位",
                    systemImage: "location",
                    status: locationStatus,
                    detail: "附近活动距离与推荐"
                )
                permissionRow(
                    title: "相册",
                    systemImage: "photo",
                    status: "按系统授权",
                    detail: "发布封面与分享图片"
                )
                permissionRow(
                    title: "日历",
                    systemImage: "calendar",
                    status: "按系统授权",
                    detail: "写入已报名活动"
                )
            } footer: {
                Text("坐标系不会在未授权时读取敏感数据。通知与跟踪会在你同意用户协议后按需请求；更改权限请前往系统设置。")
            }

            Section {
                Button("打开系统设置") {
                    NotificationService.openSystemSettings()
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("系统权限")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .task { await refresh() }
    }

    private func permissionRow(
        title: String,
        systemImage: String,
        status: String,
        detail: String
    ) -> some View {
        LabeledContent {
            Text(status)
                .foregroundStyle(.secondary)
        } label: {
            Label {
                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(title)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            } icon: {
                Image(systemName: systemImage)
            }
            .platformContentSymbolStyle()
        }
        .accessibilityElement(children: .combine)
    }

    private func refresh() async {
        let status = await NotificationService.authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral: notificationStatus = "已允许"
        case .denied: notificationStatus = "已拒绝"
        case .notDetermined: notificationStatus = "未请求"
        @unknown default: notificationStatus = "未知"
        }
        trackingStatus = PermissionLaunchPrompts.trackingStatusText
        locationStatus = location.coordinate == nil ? "未定位 / 未授权" : "已授权"
    }
}

// MARK: - Storage & export

struct SettingsStorageView: View {
    @Environment(AppModel.self) private var app
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @Environment(OpsContentStore.self) private var opsContent
    @State private var confirmClear = false
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section {
                LabeledContent("安装日", value: Formatters.conversationListTime(from: lifecycle.installAt))
                LabeledContent("打开次数", value: "\(lifecycle.openCount)")
                LabeledContent("生命周期", value: phaseLabel)
            } header: {
                Text("本机使用")
            }

            Section {
                Button("导出本机数据摘要") {
                    exportSummary()
                }
                Button("清理本地缓存", role: .destructive) {
                    confirmClear = true
                }
            } footer: {
                Text("清理会移除待发送本地通知、拉黑与举报工单中的演示噪音，并清空图片临时缓存；不会退出登录。导出为 JSON，可分享到文件 App。")
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle("存储与导出")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("清理本地缓存？", isPresented: $confirmClear) {
            Button("清理", role: .destructive) {
                app.clearLocalCaches()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                statusMessage = "已清理通知队列、拉黑与举报工单。"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("不会删除账号、钱包余额与活动报名记录。")
        }
        .alert("提示", isPresented: Binding(
            get: { statusMessage != nil },
            set: { if !$0 { statusMessage = nil } }
        )) {
            Button("好的", role: .cancel) { statusMessage = nil }
        } message: {
            Text(statusMessage ?? "")
        }
        .sheet(isPresented: $showExporter) {
            if let exportURL {
                PlatformShareSheet(items: [exportURL])
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
        }
    }

    private var phaseLabel: String {
        switch lifecycle.phase {
        case .new: "新用户"
        case .active: "活跃"
        case .returning: "回流"
        }
    }

    private func exportSummary() {
        struct ExportPayload: Encodable {
            let exportedAt: Date
            let userID: String
            let nickname: String
            let isGuest: Bool
            let openCount: Int
            let version: String
            let blockedCount: Int
            let ticketCount: Int
            let feedbackCount: Int
        }

        let payload = ExportPayload(
            exportedAt: .now,
            userID: app.user.id.uuidString,
            nickname: app.user.name,
            isGuest: false,
            openCount: lifecycle.openCount,
            version: lifecycle.versionLabel,
            blockedCount: app.blockedUserNames.count,
            ticketCount: app.moderationTickets.count,
            feedbackCount: opsContent.feedback.count
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(payload) else {
            statusMessage = "导出失败"
            return
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("coordinate-export-\(UUID().uuidString.prefix(8)).json")
        do {
            try data.write(to: url, options: [.atomic])
            exportURL = url
            showExporter = true
            statusMessage = "已生成导出文件"
        } catch {
            statusMessage = "写入导出文件失败"
        }
    }
}

// MARK: - Announcements

