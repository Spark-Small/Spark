//
//  ProfileView.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages

    @State private var showEditProfile = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    profileHeader
                }

                Section("我的数据") {
                    HStack {
                        VStack(spacing: 4) {
                            Text("\(activities.joinedActivities.count)")
                                .font(.title3.bold())
                            Text("参加")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("\(activities.hostedActivities.count)")
                                .font(.title3.bold())
                            Text("发起")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 4) {
                            Text("\(buddyConnectionCount)")
                                .font(.title3.bold())
                            Text("搭子")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, PlatformMetrics.formRowVerticalPadding)

                    NavigationLink {
                        CommunityBookmarksView()
                    } label: {
                        Label("收藏分享", systemImage: "bookmark")
                    }
                }

                Section("活动") {
                    NavigationLink {
                        ProfileActivitiesListView(
                            title: "我参加的",
                            kind: .joined,
                            emptyTitle: "还没有参加的活动",
                            emptyDescription: "去活动页报名后，会出现在这里。"
                        )
                    } label: {
                        Label("我参加的", systemImage: "ticket")
                    }

                    NavigationLink {
                        ProfileActivitiesListView(
                            title: "我发起的",
                            kind: .hosted,
                            emptyTitle: "还没有发起的活动",
                            emptyDescription: "在活动页发布活动后，会出现在这里。"
                        )
                    } label: {
                        Label("我发起的", systemImage: "flag")
                    }

                    NavigationLink {
                        ProfileActivitiesListView(
                            title: "收藏活动",
                            kind: .favorites,
                            emptyTitle: "还没有收藏",
                            emptyDescription: "收藏感兴趣的活动，方便下次查看。"
                        )
                    } label: {
                        Label("收藏活动", systemImage: "bookmark")
                    }
                }

                Section("社交") {
                    NavigationLink {
                        ProfileCirclesListView()
                    } label: {
                        Label("我的圈子", systemImage: "person.3")
                    }

                    NavigationLink {
                        ProfileNearbyBuddiesView()
                    } label: {
                        Label("附近同好", systemImage: "person.2")
                    }

                    NavigationLink {
                        ProfileBookingRecordsView()
                    } label: {
                        Label("预约过的陪玩", systemImage: "person.badge.clock")
                    }

                    NavigationLink {
                        ProfileInviteRecordsView()
                    } label: {
                        Label("邀请记录", systemImage: "paperplane")
                    }
                }
            }
            .navigationTitle("我的")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        Label("设置", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(user: Binding(
                    get: { app.user },
                    set: { updated in app.updateProfile(updated) }
                ))
            }
            .buddyOrgJoinChrome(
                buddies: buddies,
                openConversation: { app.openMessages(conversationID: $0) }
            )
        }
    }

    private var buddyConnectionCount: Int {
        let chatBuddies = Set(
            messages.conversations
                .filter { $0.kind == .direct }
                .map(\.title)
        )
        let inviteBuddies = Set(buddies.inviteRecords.map(\.nickname))
        let bookingBuddies = Set(buddies.bookingRecords.map(\.companionNickname))
        return chatBuddies.union(inviteBuddies).union(bookingBuddies).count
    }

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                ProfileAvatarView(user: app.user)

                VStack(alignment: .leading, spacing: 4) {
                    Text(app.user.name)
                        .font(.title2.bold())
                    Text(app.user.handle)
                        .foregroundStyle(.secondary)
                    Text(app.user.city)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    if !app.user.interests.isEmpty {
                        Text(app.user.interests.prefix(4).joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)

                Button {
                    showEditProfile = true
                } label: {
                    Label("编辑资料", systemImage: "pencil")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
                .accessibilityLabel("编辑资料")
            }

            Text(app.user.bio)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
    }
}

struct ProfileAvatarView: View {
    let user: AppUser

    private var photo: UIImage? {
        guard let name = user.avatarLocalName,
              let url = CommunityPhotoStore.fileURL(named: name),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else { return nil }
        return image
    }

    var body: some View {
        PlatformToolbarAvatarLabel(name: user.name, photo: photo)
    }
}

private struct EditProfileSheet: View {
    @Binding var user: AppUser
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var handle = ""
    @State private var city = ""
    @State private var bio = ""
    @State private var selectedInterests: Set<String> = []
    @State private var pickerItem: PhotosPickerItem?
    @State private var avatarPreview: UIImage?
    @State private var avatarLocalName: String?
    @State private var isPreparingAvatar = false

    var body: some View {
        NavigationStack {
            Form {
                Section("头像") {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $pickerItem, matching: .images) {
                            PlatformToolbarAvatarLabel(name: name, photo: avatarPreview)
                        }
                        .buttonStyle(.plain)
                        .onChange(of: pickerItem) { _, item in
                            Task { await loadAvatar(item) }
                        }
                        Spacer()
                    }
                    if isPreparingAvatar {
                        ProgressView("正在处理头像…")
                    }
                }

                Section("基本信息") {
                    TextField("昵称", text: $name)
                    TextField("账号", text: $handle)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("城市", text: $city)
                }

                Section {
                    InterestTaxonomyPicker(selected: $selectedInterests)
                } header: {
                    Text("兴趣")
                } footer: {
                    Text(InterestSelectionLimits.progressText(count: selectedInterests.count)
                         + "。用于活动推荐与搭子匹配。")
                }

                Section("简介") {
                    TextField("介绍一下自己…", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("编辑资料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        user.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        user.handle = handle.trimmingCharacters(in: .whitespacesAndNewlines)
                        user.city = city.trimmingCharacters(in: .whitespacesAndNewlines)
                        user.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
                        user.interests = Array(selectedInterests)
                        if let avatarLocalName {
                            if let old = user.avatarLocalName, old != avatarLocalName {
                                CommunityPhotoStore.delete(named: old)
                            }
                            user.avatarLocalName = avatarLocalName
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(
                        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || isPreparingAvatar
                            || !InterestSelectionLimits.meetsMinimum(selectedInterests.count)
                    )
                }
            }
            .onAppear {
                name = user.name
                handle = user.handle
                city = user.city
                bio = user.bio
                selectedInterests = Set(user.interests)
                avatarLocalName = user.avatarLocalName
                if let name = user.avatarLocalName,
                   let url = CommunityPhotoStore.fileURL(named: name),
                   let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    avatarPreview = image
                }
            }
        }
        .platformSheet(.browser)
    }

    @MainActor
    private func loadAvatar(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        isPreparingAvatar = true
        defer { isPreparingAvatar = false }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data),
              let saved = CommunityPhotoStore.saveJPEG(data)
        else { return }
        avatarPreview = image
        avatarLocalName = saved
    }
}

private struct ProfileSettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var confirmSignOut = false
    @State private var confirmResetDemo = false
    @State private var confirmDeleteAccount = false

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
                Button("恢复演示数据", role: .destructive) {
                    confirmResetDemo = true
                }
                Button("清空本地屏蔽与工单") {
                    app.clearLocalCaches()
                }
                Button("退出登录", role: .destructive) {
                    confirmSignOut = true
                }
                Button("注销本地账号", role: .destructive) {
                    confirmDeleteAccount = true
                }
            } footer: {
                Text("恢复演示数据会重建本机活动、消息、社区与预约样本；注销本地账号会同时清除登录态。")
            }
        }
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .confirmationDialog("恢复演示数据？", isPresented: $confirmResetDemo, titleVisibility: .visible) {
            Button("恢复演示数据", role: .destructive) {
                Task { await app.resetLocalDemoData() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会清空本机活动、消息、社区、预约、订单与已选头像，并回到默认演示样本。")
        }
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
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Label(ticket.targetKind.rawValue, systemImage: ticket.targetKind.systemImage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(ticket.status.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(moderationStatusColor(ticket.status))
                            }
                            Text(ticket.postTitle)
                                .font(.headline)
                                .lineLimit(2)
                            Text(ticket.reason)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(Formatters.conversationListTime(from: ticket.createdAt))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, PlatformMetrics.hairlineSpacing)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button("删除", systemImage: "trash", role: .destructive) {
                            app.deleteModerationTicket(ticket.id)
                        }
                        if ticket.status.nextSimulated != nil {
                            Button("推进", systemImage: "arrow.triangle.2.circlepath") {
                                app.advanceModerationTicket(ticket.id)
                            }
                            .tint(.blue)
                        }
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

                    if ticket.status.nextSimulated != nil || ticket.status == .received || ticket.status == .reviewing {
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

private func moderationStatusColor(_ status: ModerationTicketStatus) -> Color {
    switch status {
    case .received: .orange
    case .reviewing: .blue
    case .resolved: PlatformStatus.success
    case .rejected: .secondary
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

private struct SettingsAccountView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Form {
            Section("账号") {
                LabeledContent("昵称", value: app.user.name)
                LabeledContent("账号", value: app.user.handle)
                LabeledContent("登录手机", value: app.auth.phoneNumber.isEmpty ? "—" : app.auth.phoneNumber)
            }
            Section {
                Text("当前账号保存在本机。云端同步与更多登录方式将在后续版本开放。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

#Preview {
    ProfileView()
}
