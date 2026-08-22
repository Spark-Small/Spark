//
//  BuddyOrgInfoViews.swift
//  坐标系
//
//  兴趣圈子 / 陪玩工会详情：群资料骨架 + 完整加入 / 退出 / 邀请链路。
//  成员头像 → 用户资料页；「查看全部」→ 成员列表 Sheet。
//

import SwiftUI

/// 圈子「群资料」骨架（主流：加入 = 进圈子群）
struct BuddyOrgInfoScaffold<Member: Identifiable>: View {
    let infoTitle: String
    let nameLabel: String
    let displayName: String
    let memberCountLabel: Int
    let announcement: String
    let cityLine: String
    let metaRows: [(title: String, value: String)]
    let members: [Member]
    let memberName: (Member) -> String
    let memberTarget: (Member, Int) -> BuddyMemberProfileTarget?
    let isJoined: Bool
    let joinTitle: String
    let leaveTitle: String
    let pinTitle: String
    let nicknameFieldTitle: String
    let kind: OrgMembershipKind
    let reportTargetID: UUID
    var onRequestJoin: () -> Void
    var onLeave: () -> Void
    var onEnterChat: (() -> Void)? = nil
    var onInviteTap: () -> Void
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void
    var onBookMember: ((PaidCompanion) -> Void)? = nil
    /// 圈子群聊：会话标题（有则优先于 displayName）
    var chatTitle: String? = nil
    var circleConversationID: UUID? = nil
    var isGroupOwner: Bool = false
    var onSearchChat: (() -> Void)? = nil
    var onClearChatHistory: (() -> Void)? = nil
    var onDissolveCircle: (() -> Void)? = nil
    var onRenameChat: ((String) -> Void)? = nil
    /// 已加入时「我」的头像入口；未提供则不可点
    var selfMemberTarget: BuddyMemberProfileTarget? = nil

    @Environment(AppModel.self) private var app
    @Environment(MessagesModel.self) private var messages
    @State private var showAllMembers = false
    @State private var confirmLeave = false
    @State private var confirmClearHistory = false
    @State private var showMemberList = false
    @State private var showReportSheet = false
    @State private var reportReceivedMessage: String?
    @State private var showQRSheet = false
    @State private var showRenameSheet = false
    @State private var circleActionMessage: String?

    private var resolvedChatTitle: String {
        chatTitle ?? displayName
    }

    private var myGroupRole: GroupMemberRole {
        guard let circleConversationID else { return .member }
        return messages.role(of: app.user.name, in: circleConversationID)
    }

    private var canRenameChat: Bool {
        !prefs.onlyAdminCanRename || isGroupOwner || myGroupRole == .admin
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.cardInfoSpacing),
        count: 5
    )

    private var visibleMembers: [Member] {
        if showAllMembers { return members }
        return Array(members.prefix(9))
    }

    private var canExpandMembers: Bool {
        members.count > 9
    }

    private var allMemberTargets: [BuddyMemberProfileTarget] {
        members.enumerated().compactMap { memberTarget($0.element, $0.offset) }
    }

    var body: some View {
        List {
            memberSection

            if isJoined {
                if kind == .circle {
                    circleOverviewSection
                    circleChatPrefsSection
                    circleIdentitySection
                    circleClearHistorySection
                    circleLeaveSection
                } else {
                    joinedInfoSection
                    joinedPreferencesSection
                    joinedManagementSection
                }
            } else {
                metadataSection
                Section {
                    Button(joinTitle, action: onRequestJoin)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .contentMargins(.top, 0, for: .scrollContent)
        .navigationTitle("\(infoTitle) (\(memberCountLabel))")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isJoined {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("投诉", role: .destructive) {
                        showReportSheet = true
                    }
                }
            }
        }
        .alert(
            "投诉已提交",
            isPresented: Binding(
                get: { reportReceivedMessage != nil },
                set: { if !$0 { reportReceivedMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(reportReceivedMessage ?? "")
        }
        .alert(
            leaveTitle,
            isPresented: $confirmLeave
        ) {
            Button(leaveTitle, role: .destructive, action: onLeave)
            Button("取消", role: .cancel) {}
        } message: {
            Text(
                kind == .circle
                    ? "退出后将离开圈子群聊，成员设置会清除，可随时重新加入。"
                    : "退出后成员设置会清除，可随时重新加入。"
            )
        }
        .alert(
            "清空聊天记录？",
            isPresented: $confirmClearHistory
        ) {
            Button("清空", role: .destructive) {
                onClearChatHistory?()
                circleActionMessage = "聊天记录已清空"
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("仅清除本机聊天记录，不影响其他成员。")
        }
        .alert(
            "提示",
            isPresented: Binding(
                get: { circleActionMessage != nil },
                set: { if !$0 { circleActionMessage = nil } }
            )
        ) {
            Button("好的", role: .cancel) {}
        } message: {
            Text(circleActionMessage ?? "")
        }
        .sheet(isPresented: $showQRSheet) {
            CircleGroupQRSheet(title: resolvedChatTitle)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showRenameSheet) {
            CircleGroupRenameSheet(
                initialTitle: resolvedChatTitle,
                onSave: { title in
                    onRenameChat?(title)
                    circleActionMessage = "群聊名称已更新"
                }
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showMemberList) {
            BuddyMemberListSheet(
                title: BuddyMemberCopy.listTitle,
                members: allMemberTargets,
                onBook: onBookMember
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showReportSheet) {
            BuddyOrgReportSheet(targetName: displayName, kind: kind) { reason, detail, evidenceCount in
                submitReport(reason: reason, detail: detail, evidenceCount: evidenceCount)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private var muteBinding: Binding<Bool> {
        Binding(
            get: { prefs.muteNotifications },
            set: { value in
                var next = prefs
                next.muteNotifications = value
                onPrefsChange(next)
            }
        )
    }

    private var pinBinding: Binding<Bool> {
        Binding(
            get: { prefs.isPinned },
            set: { value in
                var next = prefs
                next.isPinned = value
                onPrefsChange(next)
            }
        )
    }

    private var nicknamesBinding: Binding<Bool> {
        Binding(
            get: { prefs.showMemberNicknames },
            set: { value in
                var next = prefs
                next.showMemberNicknames = value
                onPrefsChange(next)
            }
        )
    }

    private func submitReport(reason: String, detail: String, evidenceCount: Int) {
        var parts = [reason, detail]
        if evidenceCount > 0 {
            parts.append("附件 \(evidenceCount) 张")
        }
        app.addModerationTicket(
            postID: reportTargetID,
            title: displayName,
            reason: parts.joined(separator: " · "),
            targetKind: kind == .circle ? .circle : .guild
        )
        reportReceivedMessage = BuddyOrgReportCopy.receivedMessage(kind: kind)
    }

    // MARK: - Circle joined sections

    @ViewBuilder
    private var circleOverviewSection: some View {
        Section {
            if canRenameChat {
                Button {
                    showRenameSheet = true
                } label: {
                    LabeledContent(CircleGroupCopy.chatName, value: resolvedChatTitle)
                }
                .buttonStyle(.plain)
            } else {
                LabeledContent(CircleGroupCopy.chatName, value: resolvedChatTitle)
            }

            Button {
                showQRSheet = true
            } label: {
                HStack {
                    Text(CircleGroupCopy.qrCode)
                    Spacer()
                    Image(systemName: "qrcode")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(CircleGroupCopy.announcement)
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)

            NavigationLink {
                if let circleConversationID {
                    CircleGroupManageView(
                        conversationID: circleConversationID,
                        displayName: displayName,
                        prefs: prefs,
                        onPrefsChange: onPrefsChange,
                        onDissolve: {
                            onDissolveCircle?()
                        }
                    )
                }
            } label: {
                Text(CircleGroupCopy.manage)
            }
            .disabled(circleConversationID == nil)
        }
    }

    // MARK: - Circle joined sections (continued)

    @ViewBuilder
    private var circleChatPrefsSection: some View {
        Section {
            Button {
                if let onSearchChat {
                    onSearchChat()
                } else {
                    circleActionMessage = CircleGroupCopy.searchDemo
                }
            } label: {
                Text(CircleGroupCopy.searchChat)
            }

            Toggle(CircleGroupCopy.muteNotifications, isOn: muteBinding)

            if prefs.muteNotifications {
                NavigationLink {
                    CircleMutedNotifySettingsView(
                        prefs: prefs,
                        onPrefsChange: onPrefsChange
                    )
                } label: {
                    Text(CircleGroupCopy.mutedNotify)
                }
            }

            Toggle(CircleGroupCopy.pinChat, isOn: pinBinding)
        }
    }

    @ViewBuilder
    private var circleIdentitySection: some View {
        Section {
            groupNicknameLink
            Toggle(CircleGroupCopy.showMemberNicknames, isOn: nicknamesBinding)
        }
    }

    @ViewBuilder
    private var circleClearHistorySection: some View {
        Section {
            Button(CircleGroupCopy.clearHistory, role: .destructive) {
                confirmClearHistory = true
            }
            .disabled(onClearChatHistory == nil)
        }
    }

    @ViewBuilder
    private var circleLeaveSection: some View {
        Section {
            Button(leaveTitle, role: .destructive) {
                confirmLeave = true
            }
        }
    }

    // MARK: - Guild joined sections

    @ViewBuilder
    private var joinedInfoSection: some View {
        Section {
            HStack {
                Text("群二维码")
                Spacer()
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("群二维码")

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text("群公告")
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)

            if let onEnterChat {
                Button(action: onEnterChat) {
                    Label("进入群聊", systemImage: "bubble.left.and.bubble.right.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var joinedPreferencesSection: some View {
        Section {
            Toggle("消息免打扰", isOn: muteBinding)
            Toggle(pinTitle, isOn: pinBinding)
            groupNicknameLink
            Toggle("显示成员昵称", isOn: nicknamesBinding)
        }
    }

    @ViewBuilder
    private var joinedManagementSection: some View {
        Section {
            Button(leaveTitle, role: .destructive) {
                confirmLeave = true
            }
        }
    }

    // MARK: - Members

    private var memberSection: some View {
        Section {
            if members.isEmpty && !isJoined {
                ContentUnavailableView(
                    BuddyMemberCopy.emptyMembersTitle,
                    systemImage: "person.2",
                    description: Text(BuddyMemberCopy.emptyMembersDescription)
                )
                .listRowBackground(Color.clear)
                .padding(.vertical, PlatformMetrics.minContentGap)
            } else {
                LazyVGrid(columns: columns, spacing: PlatformMetrics.cardInfoSpacing) {
                    if isJoined {
                        selfMemberCell
                    }
                    ForEach(Array(visibleMembers.enumerated()), id: \.element.id) { offset, member in
                        memberCell(member, index: offset)
                    }
                    if isJoined {
                        addMemberCell
                    }
                }
                .padding(.top, PlatformMetrics.hairlineSpacing)
                .padding(.bottom, PlatformMetrics.formRowVerticalPadding)

                if canExpandMembers || !allMemberTargets.isEmpty {
                    Button {
                        if canExpandMembers, !showAllMembers {
                            withAnimation(.snappy) { showAllMembers = true }
                        } else {
                            showMemberList = true
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text(
                                canExpandMembers && !showAllMembers
                                    ? BuddyMemberCopy.moreMembers
                                    : BuddyMemberCopy.viewAllMembers
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            Image(systemName: canExpandMembers && !showAllMembers ? "chevron.down" : "list.bullet")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(BuddyMemberCopy.viewAllMembers)

                    if showAllMembers, canExpandMembers {
                        Button {
                            withAnimation(.snappy) { showAllMembers = false }
                        } label: {
                            HStack {
                                Spacer()
                                Text(BuddyMemberCopy.collapseMembers)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.up")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var myGroupNicknameLabel: String {
        GroupNicknameDisplay.settingsValue(
            realName: app.user.name,
            myGroupNickname: prefs.myGroupNickname
        )
    }

    @ViewBuilder
    private var groupNicknameLink: some View {
        NavigationLink {
            GroupNicknameEditView(
                realName: app.user.name,
                initial: myGroupNicknameLabel
            ) { saved in
                var next = prefs
                next.myGroupNickname = saved
                onPrefsChange(next)
                if let id = circleConversationID {
                    messages.setGroupAlias(saved, forMember: app.user.name, in: id)
                }
            }
        } label: {
            LabeledContent(nicknameFieldTitle, value: myGroupNicknameLabel)
        }
    }

    @ViewBuilder
    private var selfMemberCell: some View {
        let alias = prefs.myGroupNickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let display = GroupNicknameDisplay.formatted(
            realName: app.user.name,
            groupAlias: alias.isEmpty ? nil : alias
        )
        let caption = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
        if let target = selfMemberTarget {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                selfMemberAvatarStack(
                    displayName: target.profileDisplayName,
                    caption: caption,
                    accessibilityRole: target.role
                )
            }
        } else {
            selfMemberAvatarStack(
                displayName: display,
                caption: caption,
                accessibilityRole: BuddyMemberCopy.roleSelf
            )
        }
    }

    private func selfMemberAvatarStack(
        displayName: String,
        caption: String,
        accessibilityRole: String
    ) -> some View {
        VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            PlatformListAvatarView(name: displayName, side: 52)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(accessibilityRole)，\(displayName)")
    }

    @ViewBuilder
    private func memberCell(_ member: Member, index: Int) -> some View {
        let name = memberName(member)
        let label = prefs.showMemberNicknames ? truncated(name) : String(name.prefix(1))
        if let target = memberTarget(member, index) {
            CircleMemberNavigationLink(
                item: target.item,
                source: target.source,
                groupAlias: target.groupAlias
            ) {
                let display = target.profileDisplayName
                let label = prefs.showMemberNicknames ? truncated(display) : String(display.prefix(1))
                memberAvatarStack(displayName: display, label: label, role: target.role)
            }
        } else {
            memberAvatarStack(displayName: name, label: label, role: nil)
        }
    }

    private func memberAvatarStack(displayName: String, label: String, role: String?) -> some View {
        VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            PlatformListAvatarView(name: displayName, side: 52)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(
            role.map { BuddyMemberCopy.listAccessibility(nickname: displayName, role: $0) }
                ?? displayName
        )
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }

    private var addMemberCell: some View {
        Button(action: onInviteTap) {
            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                Text("邀请")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("邀请成员")
    }

    // MARK: - Metadata

    private var metadataSection: some View {
        Section {
            LabeledContent(nameLabel, value: displayName)
            LabeledContent("所在城市", value: cityLine)
            ForEach(metaRows, id: \.title) { row in
                LabeledContent(row.title, value: row.value)
            }

            HStack {
                Text("群二维码")
                Spacer()
                Image(systemName: "qrcode")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("群二维码")

            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text("群公告")
                Text(announcement)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
            .padding(.vertical, PlatformMetrics.hairlineSpacing)
        }
    }

    private func truncated(_ name: String) -> String {
        if name.count <= 4 { return name }
        return String(name.prefix(3)) + "…"
    }
}

// MARK: - Circle group copy & subpages

nonisolated enum CircleGroupCopy {
    static let chatName = "群聊名称"
    static let qrCode = "群二维码"
    static let announcement = "群公告"
    static let manage = "群管理"
    static let searchChat = "查找聊天内容"
    static let searchDemo = "演示：查找聊天内容"
    static let muteNotifications = "消息免打扰"
    static let mutedNotify = "以下消息仍然通知"
    static let pinChat = "置顶聊天"
    static let showMemberNicknames = "显示群成员昵称"
    static let clearHistory = "清空聊天记录"
    static let allowJoinViaQR = "二维码进群"
    static let joinRequiresApproval = "进群需要群主/群管理员确认"
    static let onlyAdminCanRename = "仅群主/群管理员可修改群聊名称"
    static let transferOwnership = "群主管理权转让"
    static let owner = "群主"
    static let admins = "群管理员"
    static let addAdmin = "添加群管理员"
    static let removeAdmin = "移除"
    static let adminFooter = "群管理员可确认进群申请，并协助维护群秩序。最多 3 名，不含群主。"
    static let dissolve = "解散该圈子"
    static let notifyAtMe = "@我"
    static let notifyAtAll = "@所有人"
    static let notifyAnnouncement = "群公告"
    static let mutedNotifyFooter = "开启消息免打扰后，仍可接收选定类型的提醒。"
}

struct CircleGroupManageView: View {
    static let maxAdminCount = 3

    let conversationID: UUID
    let displayName: String
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void
    var onDissolve: () -> Void

    @Environment(MessagesModel.self) private var messages
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDissolve = false
    @State private var showTransferSheet = false
    @State private var showAddAdminSheet = false
    @State private var pendingRemoveAdmin: String?

    private var conversation: ChatConversation? {
        messages.conversations.first { $0.id == conversationID }
    }

    private var circleProfileSource: BuddyProfileSource {
        if let circle = SampleData.interestCircles.first(where: { $0.name == displayName }) {
            return .circle(name: circle.name, topic: circle.topic)
        }
        return .circle(name: displayName, topic: "")
    }

    private var roster: [GroupMemberRecord] {
        messages.groupMembers(for: conversationID)
    }

    private var isOwner: Bool {
        conversation?.isOwned(by: app.user.name) == true
    }

    private var ownerMember: GroupMemberRecord? {
        roster.first { $0.role == .owner }
    }

    private var admins: [GroupMemberRecord] {
        roster.filter { $0.role == .admin }
    }

    private var adminCandidates: [GroupMemberRecord] {
        roster.filter { $0.role == .member }
    }

    private var transferCandidates: [GroupMemberRecord] {
        roster.filter { $0.role != .owner }
    }

    var body: some View {
        List {
            if let ownerMember {
                Section {
                    ownerMemberRow(ownerMember)
                } header: {
                    Text(CircleGroupCopy.owner)
                }
            }

            Section {
                Toggle(CircleGroupCopy.allowJoinViaQR, isOn: ownerPrefBinding(\.allowJoinViaQR))
                    .disabled(!isOwner)
                Toggle(CircleGroupCopy.joinRequiresApproval, isOn: ownerPrefBinding(\.joinRequiresApproval))
                    .disabled(!isOwner)
                Toggle(CircleGroupCopy.onlyAdminCanRename, isOn: ownerPrefBinding(\.onlyAdminCanRename))
                    .disabled(!isOwner)
            } footer: {
                Text(isOwner ? "进群与改名规则对本圈子群聊生效。" : "仅群主可修改以下设置。")
            }

            if isOwner {
                Section {
                    Button(CircleGroupCopy.transferOwnership) {
                        showTransferSheet = true
                    }
                    .disabled(transferCandidates.isEmpty)
                }

                Section {
                    ForEach(admins) { admin in
                        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                            PlatformListAvatarView(name: admin.nickname, side: 36)
                            Text(admin.nickname)
                            Spacer(minLength: 0)
                            Button(CircleGroupCopy.removeAdmin, role: .destructive) {
                                pendingRemoveAdmin = admin.nickname
                            }
                            .buttonStyle(.borderless)
                        }
                    }

                    if admins.count < Self.maxAdminCount {
                        Button(CircleGroupCopy.addAdmin) {
                            showAddAdminSheet = true
                        }
                        .disabled(adminCandidates.isEmpty)
                    }
                } header: {
                    Text(CircleGroupCopy.admins)
                } footer: {
                    Text(CircleGroupCopy.adminFooter)
                }

                Section {
                    Button(CircleGroupCopy.dissolve, role: .destructive) {
                        confirmDissolve = true
                    }
                }
            }
        }
        .navigationTitle(CircleGroupCopy.manage)
        .navigationBarTitleDisplayMode(.inline)
        .alert("解散该圈子？", isPresented: $confirmDissolve) {
            Button(CircleGroupCopy.dissolve, role: .destructive) {
                onDissolve()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("解散后圈子群聊将移除，成员需重新加入。")
        }
        .confirmationDialog(
            "移除群管理员？",
            isPresented: Binding(
                get: { pendingRemoveAdmin != nil },
                set: { if !$0 { pendingRemoveAdmin = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("移除", role: .destructive) {
                if let name = pendingRemoveAdmin {
                    messages.removeGroupAdmin(name, in: conversationID)
                }
                pendingRemoveAdmin = nil
            }
            Button("取消", role: .cancel) {
                pendingRemoveAdmin = nil
            }
        } message: {
            if let name = pendingRemoveAdmin {
                Text("将取消「\(name)」的群管理员身份。")
            }
        }
        .sheet(isPresented: $showTransferSheet) {
            CircleGroupTransferSheet(
                groupName: displayName,
                candidates: transferCandidates.map(\.nickname)
            ) { name in
                messages.transferGroupOwnership(to: name, in: conversationID)
            }
        }
        .sheet(isPresented: $showAddAdminSheet) {
            CircleGroupAddAdminSheet(candidates: adminCandidates.map(\.nickname)) { name in
                messages.addGroupAdmin(name, in: conversationID)
            }
        }
    }

    private func ownerPrefBinding(_ keyPath: WritableKeyPath<OrgMembershipPrefs, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs[keyPath: keyPath] },
            set: { newValue in
                guard isOwner else { return }
                var next = prefs
                next[keyPath: keyPath] = newValue
                onPrefsChange(next)
            }
        )
    }

    @ViewBuilder
    private func ownerMemberRow(_ owner: GroupMemberRecord) -> some View {
        let groupAlias = messages.groupAlias(for: owner.nickname, in: conversationID)
        let item = buddies.discoverItem(
            for: owner.nickname,
            fallbackCircleName: displayName,
            fallbackTopic: SampleData.interestCircles.first(where: { $0.name == displayName })?.topic ?? ""
        )
        CircleMemberNavigationLink(
            item: item,
            source: circleProfileSource,
            groupAlias: groupAlias
        ) {
            ownerMemberLabel(owner)
        }
    }

    private func ownerMemberLabel(_ owner: GroupMemberRecord) -> some View {
        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
            PlatformListAvatarView(name: owner.nickname, side: 36)
            Text(owner.nickname)
            Spacer(minLength: 0)
            Text(GroupMemberRole.owner.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .accessibilityHint(BuddyMemberCopy.profileTitle)
    }
}

struct CircleMutedNotifySettingsView: View {
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void

    var body: some View {
        List {
            Section {
                Toggle(CircleGroupCopy.notifyAtMe, isOn: prefBinding(\.notifyWhenMutedAtMe))
                Toggle(CircleGroupCopy.notifyAtAll, isOn: prefBinding(\.notifyWhenMutedAtAll))
                Toggle(CircleGroupCopy.notifyAnnouncement, isOn: prefBinding(\.notifyWhenMutedAnnouncement))
            } footer: {
                Text(CircleGroupCopy.mutedNotifyFooter)
            }
        }
        .navigationTitle(CircleGroupCopy.mutedNotify)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prefBinding(_ keyPath: WritableKeyPath<OrgMembershipPrefs, Bool>) -> Binding<Bool> {
        Binding(
            get: { prefs[keyPath: keyPath] },
            set: { newValue in
                var next = prefs
                next[keyPath: keyPath] = newValue
                onPrefsChange(next)
            }
        )
    }
}

private struct CircleGroupQRSheet: View {
    let title: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: PlatformMetrics.sectionSpacing) {
                Spacer(minLength: PlatformMetrics.cardFooterSpacing)
                Image(systemName: "qrcode")
                    .font(.system(size: 160))
                    .foregroundStyle(.primary)
                    .platformSymbolStyle(.hierarchical)
                Text(title)
                    .font(.headline)
                Text("扫码加入「\(title)」")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding()
            .navigationTitle(CircleGroupCopy.qrCode)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .platformSheet(.confirm)
    }
}

private struct CircleGroupRenameSheet: View {
    let initialTitle: String
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(CircleGroupCopy.chatName, text: $draft)
                }
            }
            .navigationTitle("修改群聊名称")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { draft = initialTitle }
        }
        .platformSheet(.form)
    }
}

private struct CircleGroupTransferSheet: View {
    let groupName: String
    let candidates: [String]
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if candidates.isEmpty {
                        Text("暂无可转让的成员")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(candidates, id: \.self) { name in
                            Button {
                                onSelect(name)
                                dismiss()
                            } label: {
                                HStack {
                                    PlatformListAvatarView(name: name, side: 36)
                                    Text(name)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } footer: {
                    Text("转让后，你将失去群主权限，对方成为新群主。")
                }
            }
            .navigationTitle(CircleGroupCopy.transferOwnership)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}

private struct CircleGroupAddAdminSheet: View {
    let candidates: [String]
    var onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if candidates.isEmpty {
                        Text("暂无可添加的成员")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(candidates, id: \.self) { name in
                            Button {
                                onSelect(name)
                                dismiss()
                            } label: {
                                HStack {
                                    PlatformListAvatarView(name: name, side: 36)
                                    Text(name)
                                        .foregroundStyle(.primary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } footer: {
                    Text("群管理员可协助确认进群申请；不含群主，最多 \(CircleGroupManageView.maxAdminCount) 名。")
                }
            }
            .navigationTitle(CircleGroupCopy.addAdmin)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
        }
        .platformSheet(.form)
    }
}

private extension Array where Element == String {
    func uniqued() -> [String] {
        var seen = Set<String>()
        return filter { seen.insert($0).inserted }
    }
}

private struct GroupNicknameEditView: View {
    let realName: String
    let initial: String
    var onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String

    init(realName: String, initial: String, onSave: @escaping (String) -> Void) {
        self.realName = realName
        self.initial = initial
        self.onSave = onSave
        _draft = State(initialValue: initial)
    }

    var body: some View {
        Form {
            Section {
                TextField("本群昵称", text: $draft)
                    .textInputAutocapitalization(.never)
            } footer: {
                Text("保存后，其他成员在群内将看到「\(realName)（本群昵称）」形式展示。")
            }
        }
        .navigationTitle("我在本群的昵称")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Circle detail

struct ProfileCircleDetailView: View {
    let circle: InterestCircle

    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    private var isJoined: Bool { buddies.isJoined(circle) }

    private var circleConversation: ChatConversation? {
        messages.conversation(forCircleID: circle.id)
    }

    private var members: [DiscoverBuddyItem] {
        SampleData.circleBuddies
            .filter { $0.circleName == circle.name }
            .map(DiscoverBuddyItem.free)
    }

    /// 详情页标题与成员区对齐，不用浏览卡片上的种子 `memberCount`。
    private var memberCountLabel: Int {
        members.count + (isJoined ? 1 : 0)
    }

    private var profileSource: BuddyProfileSource {
        .circle(name: circle.name, topic: circle.topic)
    }

    private func memberRoleLabel(for nickname: String) -> String {
        if let id = circleConversation?.id {
            switch messages.role(of: nickname, in: id) {
            case .owner:
                return GroupMemberRole.owner.rawValue
            case .admin:
                return GroupMemberRole.admin.rawValue
            case .member:
                return BuddyMemberCopy.roleMember
            }
        }
        return BuddyMemberCopy.roleMember
    }

    private func memberProfileTarget(
        for item: DiscoverBuddyItem,
        groupAlias: String?
    ) -> BuddyMemberProfileTarget {
        BuddyMemberProfileTarget(
            item: item,
            source: profileSource,
            role: memberRoleLabel(for: item.profile.nickname),
            groupAlias: groupAlias
        )
    }

    private func selfMemberProfileTarget() -> BuddyMemberProfileTarget? {
        guard isJoined else { return nil }
        let name = app.user.name
        let groupAlias = circleConversation.flatMap {
            messages.groupAlias(for: name, in: $0.id)
        }
        return memberProfileTarget(
            for: buddies.discoverItem(
                for: name,
                fallbackCircleName: circle.name,
                fallbackTopic: circle.topic
            ),
            groupAlias: groupAlias
        )
    }

    var body: some View {
        BuddyOrgInfoScaffold(
            infoTitle: "圈子信息",
            nameLabel: "圈子名称",
            displayName: circle.name,
            memberCountLabel: memberCountLabel,
            announcement: circle.summary,
            cityLine: circle.city,
            metaRows: [
                ("主题", circle.topic),
                ("周活跃", "\(circle.weeklyActive)"),
            ],
            members: members,
            memberName: { $0.profile.nickname },
            memberTarget: { item, _ in
                memberProfileTarget(
                    for: item,
                    groupAlias: circleConversation.flatMap {
                        messages.groupAlias(for: item.profile.nickname, in: $0.id)
                    }
                )
            },
            isJoined: isJoined,
            joinTitle: "加入圈子",
            leaveTitle: "退出群聊",
            pinTitle: "置顶聊天",
            nicknameFieldTitle: "我在本群的昵称",
            kind: .circle,
            reportTargetID: circle.id,
            onRequestJoin: { buddies.beginJoin(.circle(circle)) },
            onLeave: {
                messages.leaveCircleChat(circleID: circle.id, leaverName: app.user.name)
                buddies.leaveCircle(circle)
                dismiss()
            },
            onEnterChat: { openCircleChat() },
            onInviteTap: { buddies.beginInvite(to: .circle(circle)) },
            prefs: buddies.prefs(kind: .circle, name: circle.name),
            onPrefsChange: { next in
                let previous = buddies.prefs(kind: .circle, name: circle.name)
                buddies.updatePrefs(kind: .circle, name: circle.name) { $0 = next }
                if let id = circleConversation?.id {
                    if previous.isPinned != next.isPinned {
                        messages.togglePin(id)
                    }
                    if previous.muteNotifications != next.muteNotifications {
                        messages.toggleMute(id)
                    }
                }
            },
            chatTitle: circleConversation?.title,
            circleConversationID: circleConversation?.id,
            isGroupOwner: circleConversation?.isOwned(by: app.user.name) == true,
            onSearchChat: nil,
            onClearChatHistory: {
                guard let id = circleConversation?.id else { return }
                messages.clearChatHistory(in: id)
            },
            onDissolveCircle: {
                messages.leaveCircleChat(circleID: circle.id, leaverName: app.user.name)
                buddies.leaveCircle(circle)
                dismiss()
            },
            onRenameChat: { title in
                guard let id = circleConversation?.id else { return }
                messages.renameGroup(title, for: id)
            },
            selfMemberTarget: selfMemberProfileTarget()
        )
    }

    private func openCircleChat() {
        if let convo = messages.startCircleChat(for: circle, memberName: app.user.name) {
            app.openMessages(conversationID: convo.id)
        }
    }
}

struct ProfileGuildsListView: View {
    @Environment(BuddiesModel.self) private var buddies

    var body: some View {
        List {
            if buddies.joinedGuilds.isEmpty {
                ContentUnavailableView(
                    "还没有关注工会",
                    systemImage: "building.2",
                    description: Text("在搭子 · 陪玩页关注工会后，会出现在这里。")
                )
                .listRowBackground(Color.clear)
            } else {
                ForEach(buddies.joinedGuilds) { guild in
                    NavigationLink(value: guild) {
                        HStack(spacing: PlatformMetrics.cardFooterSpacing) {
                            Image(systemName: guild.systemImage)
                                .font(.title3)
                                .foregroundStyle(PlatformStatus.warning)
                                .frame(width: 36, height: 36)
                                .background(
                                    PlatformStatus.warning.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                                )
                            VStack(alignment: .leading, spacing: 4) {
                                Text(guild.name)
                                    .font(.body.weight(.medium))
                                    .lineLimit(1)
                                Text("\(guild.specialty) · \(guild.city)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, PlatformMetrics.hairlineSpacing)
                    }
                }
            }
        }
        .navigationTitle("我的工会")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: CompanionGuild.self) { guild in
            BuddyGuildDetailView(guild: guild)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}
