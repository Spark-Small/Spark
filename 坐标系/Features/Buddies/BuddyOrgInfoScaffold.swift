//
//  BuddyOrgInfoScaffold.swift
//  坐标系
//
//  兴趣圈子 / 陪玩工会详情骨架与成员网格。
//

import SwiftUI
import CoordinateModels

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
                    ? "退出后将离开俱乐部群聊，成员设置会清除，可随时重新加入。"
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
            if let onEnterChat {
                Button(action: onEnterChat) {
                    Label("进入群聊", systemImage: "bubble.left.and.bubble.right.fill")
                }
            }

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
                            PlatformMotion.withAnimation(.snappy) { showAllMembers = true }
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
                            PlatformMotion.withAnimation(.snappy) { showAllMembers = false }
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
