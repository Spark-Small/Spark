//
//  CircleGroupManageViews.swift
//  坐标系
//
//  圈子群管理子页与文案。
//

import SwiftUI
import CoordinateModels

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
    static let dissolve = "解散该俱乐部"
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
        if let circle = buddies.circle(named: displayName) {
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
                Text(isOwner ? "进群与改名规则对本俱乐部群聊生效。" : "仅群主可修改以下设置。")
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
        .alert("解散该俱乐部？", isPresented: $confirmDissolve) {
            Button(CircleGroupCopy.dissolve, role: .destructive) {
                onDissolve()
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("解散后俱乐部群聊将移除，成员需重新加入。")
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

struct CircleGroupQRSheet: View {
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

struct CircleGroupRenameSheet: View {
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

struct GroupNicknameEditView: View {
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

