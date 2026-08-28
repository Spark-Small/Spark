//
//  ProfileSettingsViews.swift
//  坐标系
//
//  「我的」设置及账号 / 通知 / 隐私 / 举报 / 关于子页。
//

import SwiftUI
import UIKit

struct ProfileSettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var confirmSignOut = false
    @State private var confirmDeleteAccount = false
    #if DEBUG
    @State private var confirmResetDemo = false
    @State private var confirmClearCaches = false
    #endif

    var body: some View {
        List {
            Section {
                NavigationLink {
                    SettingsAccountView()
                } label: {
                    Label("账号与安全", systemImage: "lock.shield")
                        .platformContentSymbolStyle()
                }
            }

            Section {
                NavigationLink {
                    SettingsNotificationsView()
                } label: {
                    Label("通知设置", systemImage: "bell.badge")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsPrivacyView()
                } label: {
                    Label("隐私", systemImage: "hand.raised.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsPermissionsView()
                } label: {
                    Label("系统权限", systemImage: "checkmark.shield")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsYouthModeView()
                } label: {
                    Label("青少年模式", systemImage: "figure.and.child.holdinghands")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("隐私与安全")
            }

            Section {
                NavigationLink {
                    SettingsHelpFeedbackView()
                } label: {
                    Label("帮助与反馈", systemImage: "questionmark.circle")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    UserAgreementView()
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    Label("用户协议", systemImage: "doc.text")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    PrivacyPolicyView()
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    Label("隐私政策", systemImage: "hand.raised")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsAnnouncementsView()
                } label: {
                    Label("运营公告", systemImage: "megaphone")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    SettingsStorageView()
                } label: {
                    Label("存储与导出", systemImage: "externaldrive")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    ModerationTicketsView()
                } label: {
                    Label("举报记录", systemImage: "flag.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink {
                    BlockedUsersView()
                } label: {
                    Label("已拉黑", systemImage: "hand.raised.slash")
                        .platformContentSymbolStyle()
                }
            } header: {
                Text("帮助与反馈")
            }

            Section {
                NavigationLink {
                    SettingsAboutView()
                } label: {
                    Label("关于坐标系", systemImage: "info.circle")
                        .platformContentSymbolStyle()
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
                Button("清空本地屏蔽与工单", role: .destructive) {
                    confirmClearCaches = true
                }
            } header: {
                Text("开发者")
            } footer: {
                Text("仅调试构建可见。恢复演示数据会重建本机活动、消息、社区与预约样本。")
            }
            #endif
        }
        .profileSecondaryListChrome()
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .platformHiddenTabBar()
        #if DEBUG
        .confirmationDialog("恢复演示数据？", isPresented: $confirmResetDemo, titleVisibility: .visible) {
            Button("恢复演示数据", role: .destructive) {
                Task { await app.resetLocalDemoData() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会清空本机活动、消息、社区、预约、订单与已选头像，并回到默认演示样本。")
        }
        .alert("清空本地屏蔽与工单？", isPresented: $confirmClearCaches) {
            Button("清空", role: .destructive) {
                app.clearLocalCaches()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("此操作只清除本机屏蔽名单与举报工单，且无法恢复。")
        }
        #endif
        .alert("退出登录？", isPresented: $confirmSignOut) {
            Button("退出登录", role: .destructive) {
                Task { await app.signOutLocally() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(ProfileDashboardCopy.logoutConfirmMessage)
        }
        .alert("注销本地账号？", isPresented: $confirmDeleteAccount) {
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
    @AppStorage("profile.membership.active") private var membershipActive = false
    @State private var showCreateAccount = false
    @State private var showEditProfile = false

    private var completionPercent: Int {
        Int((ProfileCompletion.ratio(for: app.user) * 100).rounded())
    }

    private var photoVerified: Bool {
        _ = PhotoVerificationStore.shared.isVerified
        return PhotoVerificationStore.shared.isVerified(for: app.user.name)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    ProfileAvatarView(user: app.user)
                    VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                        Text(app.user.name)
                            .font(.headline)
                        Text(app.auth.accountStatusLabel)
                            .font(.subheadline)
                            .foregroundStyle(app.auth.isGuest ? PlatformStatus.warning : .secondary)
                        Text("资料完整度 \(completionPercent)%")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        if !app.auth.isGuest {
                            TrustCredentialBadgeStrip(
                                photoVerified: photoVerified,
                                isMember: membershipActive,
                                revealLocked: true
                            )
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }

            if !app.auth.isGuest {
                Section {
                    TrustCredentialStatusRows(
                        photoVerified: photoVerified,
                        isMember: membershipActive
                    )
                    NavigationLink {
                        PhotoVerificationView()
                    } label: {
                        Label(
                            photoVerified ? "管理形象认证" : "开始形象认证",
                            systemImage: photoVerified ? "checkmark.seal.fill" : "camera.viewfinder"
                        )
                        .platformContentSymbolStyle()
                    }
                    NavigationLink {
                        ProfileMembershipView()
                    } label: {
                        Label(
                            membershipActive ? "会员中心" : "开通会员",
                            systemImage: membershipActive ? "checkmark.seal.fill" : "checkmark.seal"
                        )
                        .platformContentSymbolStyle()
                    }
                } header: {
                    Text("认证与徽章")
                }
            }

            Section("身份") {
                LabeledContent("登录状态", value: app.auth.accountStatusLabel)
                LabeledContent("登录方式", value: app.auth.loginMethodLabel)
                LabeledContent("手机号", value: app.auth.maskedPhoneLabel)
                LabeledContent("昵称", value: app.user.name)
                LabeledContent("账号", value: app.user.handle.isEmpty ? "—" : app.user.handle)
                LabeledContent("常驻城市", value: app.user.city.isEmpty ? "—" : app.user.city)
            }

            Section {
                if app.auth.isGuest {
                    Button("创建账号，升级身份") {
                        showCreateAccount = true
                    }
                    .fontWeight(.semibold)
                } else {
                    Button("编辑个人资料") {
                        showEditProfile = true
                    }
                }
            } footer: {
                Text(
                    app.auth.isGuest
                        ? GuestAccessGate.identityReason
                        : "完善头像、兴趣与简介，有助于搭子匹配与活动推荐。"
                )
            }

            Section {
                LabeledContent("UID", value: app.user.publicUIDDisplay)
                    .textSelection(.enabled)
                Button(MessagesCopy.copyUID) {
                    UIPasteboard.general.string = app.user.publicUID
                }
            } header: {
                Text("对外 UID")
            } footer: {
                Text("9 位数字账号，可复制给朋友用于添加好友。内部仍使用稳定 UUID，注销后会重新分配。")
            }
        }
        .navigationTitle("账号与安全")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .sheet(isPresented: $showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: GuestAccessGate.identityReason
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: Binding(
                get: { app.user },
                set: { updated in app.updateProfile(updated) }
            ))
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}

struct SettingsNotificationsView: View {
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

struct SettingsPrivacyView: View {
    @AppStorage(PrivacyPreferenceKey.showDistance) private var showDistance = true
    @AppStorage(PrivacyPreferenceKey.showOnline) private var showOnline = true
    @AppStorage(PrivacyPreferenceKey.allowInvite) private var allowInvite = true

    var body: some View {
        Form {
            Section {
                Toggle("展示大致距离", isOn: $showDistance)
                Toggle("展示在线状态", isOn: $showOnline)
                Toggle("允许陌生人邀约", isOn: $allowInvite)
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

private struct SettingsAboutView: View {
    @State private var updateMessage: String?

    private var version: String {
        ProductLifecycleStore.shared.versionLabel
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

private struct ModerationTicketsView: View {
    @Environment(AppModel.self) private var app
    @State private var pendingDeleteID: ModerationTicket.ID?

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
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            pendingDeleteID = ticket.id
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
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("删除工单？", isPresented: Binding(
            get: { pendingDeleteID != nil },
            set: { if !$0 { pendingDeleteID = nil } }
        )) {
            Button("删除", role: .destructive) {
                if let pendingDeleteID {
                    app.deleteModerationTicket(pendingDeleteID)
                }
                pendingDeleteID = nil
            }
            Button("取消", role: .cancel) {
                pendingDeleteID = nil
            }
        } message: {
            Text("删除后无法恢复，仅清除本机举报记录。")
        }
    }
}

private struct ModerationTicketDetailView: View {
    let ticketID: ModerationTicket.ID
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

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
                            confirmDelete = true
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
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("删除工单？", isPresented: $confirmDelete) {
            Button("删除", role: .destructive) {
                app.deleteModerationTicket(ticketID)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("删除后无法恢复，仅清除本机举报记录。")
        }
    }
}

struct BlockedUsersView: View {
    @Environment(AppModel.self) private var app
    @State private var pendingUnblockName: String?

    var body: some View {
        List {
            if app.blockedUserNames.isEmpty {
                ContentUnavailableView("未拉黑任何人", systemImage: "person.crop.circle.badge.checkmark")
            } else {
                ForEach(Array(app.blockedUserNames).sorted(), id: \.self) { name in
                    Text(name)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("解除", role: .destructive) {
                                pendingUnblockName = name
                            }
                        }
                }
            }
        }
        .navigationTitle("已拉黑")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarVisibility(.hidden, for: .tabBar)
        .alert("解除拉黑？", isPresented: Binding(
            get: { pendingUnblockName != nil },
            set: { if !$0 { pendingUnblockName = nil } }
        )) {
            Button("解除", role: .destructive) {
                if let pendingUnblockName {
                    app.unblockUser(pendingUnblockName)
                }
                pendingUnblockName = nil
            }
            Button("取消", role: .cancel) {
                pendingUnblockName = nil
            }
        } message: {
            Text(pendingUnblockName.map { "将解除对 \($0) 的拉黑。" } ?? "")
        }
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
