//
//  ProfileSettingsViews.swift
//  坐标系
//
//  「我的」设置及账号 / 通知 / 隐私 / 举报 / 关于子页。
//

import SwiftUI

struct ProfileSettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var confirmSignOut = false
    @State private var confirmDeleteAccount = false
    #if DEBUG
    @State private var confirmResetDemo = false
    #endif

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SettingsAccountView()
                } label: {
                    Label("账号与安全", systemImage: "lock.shield")
                }

                NavigationLink {
                    SettingsNotificationsView()
                } label: {
                    Label("通知设置", systemImage: "bell")
                }

                NavigationLink {
                    SettingsPrivacyView()
                } label: {
                    Label("隐私", systemImage: "hand.raised")
                }

                NavigationLink {
                    ModerationTicketsView()
                } label: {
                    Label("举报记录", systemImage: "flag")
                }

                NavigationLink {
                    BlockedUsersView()
                } label: {
                    Label("已拉黑", systemImage: "hand.raised.slash")
                }

                NavigationLink {
                    SettingsAboutView()
                } label: {
                    Label("关于坐标系", systemImage: "info.circle")
                }
            }

            Section {
                Button("退出登录", role: .destructive) {
                    confirmSignOut = true
                }
                Button("注销本地账号", role: .destructive) {
                    confirmDeleteAccount = true
                }
            } footer: {
                Text("注销本地账号会清除登录态与本机资料，并回到首次打开状态。")
            }

            #if DEBUG
            Section {
                Button("恢复演示数据", role: .destructive) {
                    confirmResetDemo = true
                }
                Button("清空本地屏蔽与工单") {
                    app.clearLocalCaches()
                }
            } header: {
                Text("开发者")
            } footer: {
                Text("仅调试构建可见。恢复演示数据会重建本机活动、消息、社区与预约样本。")
            }
            #endif
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        #if DEBUG
        .confirmationDialog("恢复演示数据？", isPresented: $confirmResetDemo, titleVisibility: .visible) {
            Button("恢复演示数据", role: .destructive) {
                Task { await app.resetLocalDemoData() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会清空本机活动、消息、社区、预约、订单与已选头像，并回到默认演示样本。")
        }
        #endif
        .confirmationDialog("退出登录？", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("退出登录", role: .destructive) {
                Task { await app.signOutLocally() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("将返回登录与引导流程。")
        }
        .confirmationDialog("注销本地账号？", isPresented: $confirmDeleteAccount, titleVisibility: .visible) {
            Button("注销本地账号", role: .destructive) {
                Task { await app.deleteLocalAccount() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会删除本机登录态、资料、活动、消息、社区、预约与工单，并回到首次打开状态。")
        }
    }
}

private struct SettingsAccountView: View {
    @Environment(AppModel.self) private var app

    private var loginValue: String {
        if app.auth.isGuest { return "访客" }
        return app.auth.phoneNumber.isEmpty ? "—" : app.auth.phoneNumber
    }

    var body: some View {
        Form {
            Section("账号") {
                LabeledContent("昵称", value: app.user.name)
                LabeledContent("账号", value: app.user.handle)
                LabeledContent("登录方式", value: loginValue)
                LabeledContent("常驻城市", value: app.user.city.isEmpty ? "—" : app.user.city)
            }

            Section {
                LabeledContent("用户 ID", value: app.user.id.uuidString)
                    .textSelection(.enabled)
            } header: {
                Text("身份")
            } footer: {
                Text("本机稳定 UUID，游客与登录用户都会获得。当前账号数据保存在本机。")
            }
        }
        .navigationTitle("账号与安全")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct SettingsNotificationsView: View {
    @AppStorage(NotificationService.PreferenceKey.activity) private var activityReminders = true
    @AppStorage(NotificationService.PreferenceKey.buddy) private var buddyOnline = true
    @AppStorage(NotificationService.PreferenceKey.message) private var messagePush = true
    @AppStorage(NotificationService.PreferenceKey.community) private var communityDigest = false
    @State private var authStatusText = "读取中…"
    @State private var showDeniedHint = false

    var body: some View {
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
                Toggle("活动提醒", isOn: $activityReminders)
                    .onChange(of: activityReminders) { _, enabled in
                        if enabled { Task { await requestIfNeeded() } }
                    }
                Toggle("搭子上线通知", isOn: $buddyOnline)
                Toggle("新消息通知", isOn: $messagePush)
                Toggle("社区精选摘要", isOn: $communityDigest)
            } header: {
                Text("推送偏好（本地）")
            } footer: {
                Text("开启活动提醒时会请求系统通知权限，并在报名/预约后写入本地提醒。")
            }
        }
        .navigationTitle("通知设置")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
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

private struct SettingsPrivacyView: View {
    @AppStorage("settings.privacy.showDistance") private var showDistance = true
    @AppStorage("settings.privacy.showOnline") private var showOnline = true
    @AppStorage("settings.privacy.allowInvite") private var allowInvite = true

    var body: some View {
        Form {
            Section("资料可见性") {
                Toggle("展示大致距离", isOn: $showDistance)
                Toggle("展示在线状态", isOn: $showOnline)
                Toggle("允许陌生人邀约", isOn: $allowInvite)
            }
        }
        .navigationTitle("隐私")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct SettingsAboutView: View {
    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                LabeledContent("版本", value: version)
                LabeledContent("产品", value: "坐标系")
            }
            Section("说明") {
                Text("坐标系帮你发现活动、找到搭子，并把社区分享与消息串成一条闭环。")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            Section("合规") {
                NavigationLink("用户协议") { UserAgreementView() }
                NavigationLink("隐私政策") { PrivacyPolicyView() }
            }
        }
        .navigationTitle("关于坐标系")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct ModerationTicketsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if app.moderationTickets.isEmpty {
                ContentUnavailableView(
                    "暂无举报",
                    systemImage: "flag",
                    description: Text("社区、活动、消息或搭子举报后会出现在这里。")
                )
            } else {
                ForEach(app.moderationTickets) { ticket in
                    NavigationLink {
                        ModerationTicketDetailView(ticketID: ticket.id)
                    } label: {
                        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                            HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                                Label(ticket.targetKind.rawValue, systemImage: ticket.targetKind.systemImage)
                                    .font(PlatformListTypography.footnote)
                                    .foregroundStyle(.secondary)
                                Spacer(minLength: 0)
                                Text(ticket.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(moderationStatusColor(ticket.status))
                            }
                            Text(ticket.postTitle)
                                .font(PlatformListTypography.primary)
                                .lineLimit(2)
                            Text(ticket.reason)
                                .font(PlatformListTypography.secondary)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: ticket.createdAt))
                                .font(PlatformListTypography.footnote)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            app.deleteModerationTicket(ticket.id)
                        }
                        #if DEBUG
                        if ticket.status.nextSimulated != nil {
                            Button("推进", systemImage: "arrow.triangle.2.circlepath") {
                                app.advanceModerationTicket(ticket.id)
                            }
                            .tint(.blue)
                        }
                        #endif
                    }
                }
            }
        }
        .navigationTitle("举报记录")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct ModerationTicketDetailView: View {
    let ticketID: ModerationTicket.ID
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var ticket: ModerationTicket? {
        app.moderationTickets.first { $0.id == ticketID }
    }

    var body: some View {
        Group {
            if let ticket {
                Form {
                    Section {
                        LabeledContent("类型", value: ticket.targetKind.rawValue)
                        LabeledContent("状态") {
                            Text(ticket.status.rawValue)
                                .foregroundStyle(moderationStatusColor(ticket.status))
                                .fontWeight(.semibold)
                        }
                        LabeledContent("对象", value: ticket.postTitle)
                        LabeledContent("原因", value: ticket.reason)
                        LabeledContent(
                            "提交",
                            value: Formatters.activityDate.string(from: ticket.createdAt)
                        )
                        if let updatedAt = ticket.updatedAt {
                            LabeledContent(
                                "更新",
                                value: Formatters.activityDate.string(from: updatedAt)
                            )
                        }
                    }

                    #if DEBUG
                    if ticket.status.nextSimulated != nil
                        || ticket.status == .received
                        || ticket.status == .reviewing {
                        Section {
                            if let next = ticket.status.nextSimulated {
                                Button("推进为「\(next.rawValue)」", systemImage: "arrow.triangle.2.circlepath") {
                                    app.advanceModerationTicket(ticket.id)
                                }
                            }
                            if ticket.status == .received || ticket.status == .reviewing {
                                Button("驳回工单", systemImage: "xmark.circle", role: .destructive) {
                                    app.rejectModerationTicket(ticket.id)
                                }
                            }
                        } header: {
                            Text("本地演示")
                        } footer: {
                            Text("正式产品由运营后台处置；此处可手动推进状态机。")
                        }
                    }
                    #endif

                    Section {
                        Button("删除工单", role: .destructive) {
                            app.deleteModerationTicket(ticket.id)
                            dismiss()
                        }
                    }
                }
            } else {
                ContentUnavailableView("工单不存在", systemImage: "flag")
                    .onAppear { dismiss() }
            }
        }
        .navigationTitle("工单详情")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private struct BlockedUsersView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            if app.blockedUserNames.isEmpty {
                ContentUnavailableView("未拉黑任何人", systemImage: "person.crop.circle.badge.checkmark")
            } else {
                ForEach(Array(app.blockedUserNames).sorted(), id: \.self) { name in
                    HStack {
                        Text(name)
                        Spacer()
                        Button("解除") { app.unblockUser(name) }
                            .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("已拉黑")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
    }
}

private func moderationStatusColor(_ status: ModerationTicketStatus) -> Color {
    switch status {
    case .received: .orange
    case .reviewing: .blue
    case .resolved: PlatformStatus.success
    case .rejected: .secondary
    }
}
