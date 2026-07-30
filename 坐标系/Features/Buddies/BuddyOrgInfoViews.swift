//
//  BuddyOrgInfoViews.swift
//  坐标系
//
//  兴趣组织 / 陪玩工会详情：群资料骨架 + 完整加入 / 退出 / 邀请链路。
//  成员头像 → 半屏资料卡（不 Zoom）；「查看全部」→ 成员列表 Sheet。
//

import SwiftUI

/// 组织「群资料」骨架（主流：加入 = 进组织群）
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
    var onRequestJoin: () -> Void
    var onLeave: () -> Void
    var onEnterChat: (() -> Void)? = nil
    var onInviteTap: () -> Void
    var onSearchTap: () -> Void
    var onReport: () -> Void
    var prefs: OrgMembershipPrefs
    var onPrefsChange: (OrgMembershipPrefs) -> Void
    var onMessageMember: (DiscoverBuddyItem) -> Void
    var onBookMember: ((PaidCompanion) -> Void)? = nil

    @Environment(AppModel.self) private var app
    @State private var showAllMembers = false
    @State private var confirmLeave = false
    @State private var selectedMember: BuddyMemberProfileTarget?
    @State private var showMemberList = false

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
            metadataSection

            if isJoined {
                if let onEnterChat {
                    Section {
                        Button(action: onEnterChat) {
                            Label("进入群聊", systemImage: "bubble.left.and.bubble.right.fill")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }

                Section {
                    Button(action: onSearchTap) {
                        Text("查找相关内容")
                            .foregroundStyle(.primary)
                    }
                }

                Section {
                    Toggle("消息免打扰", isOn: muteBinding)
                    Toggle(pinTitle, isOn: pinBinding)
                }

                Section {
                    LabeledContent(nicknameFieldTitle, value: app.user.name)
                    Toggle("显示成员昵称", isOn: nicknamesBinding)
                }

                Section {
                    Button("投诉", role: .destructive, action: onReport)
                }

                Section {
                    Button(leaveTitle, role: .destructive) {
                        confirmLeave = true
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                Section {
                    Text("加入后进入组织群聊，可查看成员、公告，并邀请好友。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button(joinTitle, action: onRequestJoin)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("\(infoTitle) (\(memberCountLabel))")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            leaveTitle,
            isPresented: $confirmLeave
        ) {
            Button(leaveTitle, role: .destructive, action: onLeave)
            Button("取消", role: .cancel) {}
        } message: {
            Text(
                kind == .circle
                    ? "退出后将离开组织群聊，成员设置会清除，可随时重新加入。"
                    : "退出后成员设置会清除，可随时重新加入。"
            )
        }
        .sheet(item: $selectedMember) { target in
            BuddyMemberProfileSheet(
                target: target,
                onMessage: onMessageMember,
                onBook: onBookMember
            )
        }
        .sheet(isPresented: $showMemberList) {
            BuddyMemberListSheet(
                title: BuddyMemberCopy.listTitle,
                members: allMemberTargets,
                onMessage: onMessageMember,
                onBook: onBookMember
            )
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

    private var remarkBinding: Binding<String> {
        Binding(
            get: { prefs.remark },
            set: { value in
                var next = prefs
                next.remark = value
                onPrefsChange(next)
            }
        )
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
                .padding(.vertical, 8)
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
                .padding(.vertical, PlatformMetrics.formRowVerticalPadding)

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

    private var selfMemberCell: some View {
        VStack(spacing: 6) {
            PlatformListAvatarView(name: app.user.name, side: 52)
            Text(prefs.showMemberNicknames ? truncated(app.user.name) : String(app.user.name.prefix(1)))
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("\(BuddyMemberCopy.roleSelf)，\(app.user.name)")
    }

    @ViewBuilder
    private func memberCell(_ member: Member, index: Int) -> some View {
        let name = memberName(member)
        let label = prefs.showMemberNicknames ? truncated(name) : String(name.prefix(1))
        if let target = memberTarget(member, index) {
            Button {
                selectedMember = target
            } label: {
                memberAvatarStack(displayName: name, label: label, role: target.role)
            }
            .buttonStyle(.plain)
        } else {
            memberAvatarStack(displayName: name, label: label, role: nil)
        }
    }

    private func memberAvatarStack(displayName: String, label: String, role: String?) -> some View {
        VStack(spacing: 6) {
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
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
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
            .padding(.vertical, 2)

            if isJoined {
                TextField("备注", text: remarkBinding, prompt: Text("添加备注"))
            }
        }
    }

    private func truncated(_ name: String) -> String {
        if name.count <= 4 { return name }
        return String(name.prefix(3)) + "…"
    }
}

// MARK: - Circle detail

struct ProfileCircleDetailView: View {
    let circle: InterestCircle

    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @State private var toast: String?

    private var isJoined: Bool { buddies.isJoined(circle) }

    private var members: [DiscoverBuddyItem] {
        SampleData.circleBuddies
            .filter { $0.circleName == circle.name }
            .map(DiscoverBuddyItem.free)
    }

    private var profileSource: BuddyProfileSource {
        .circle(name: circle.name, topic: circle.topic)
    }

    var body: some View {
        BuddyOrgInfoScaffold(
            infoTitle: "组织信息",
            nameLabel: "组织名称",
            displayName: circle.name,
            memberCountLabel: max(circle.memberCount, members.count + (isJoined ? 1 : 0)),
            announcement: circle.summary,
            cityLine: circle.city,
            metaRows: [
                ("主题", circle.topic),
                ("周活跃", "\(circle.weeklyActive)"),
            ],
            members: members,
            memberName: { $0.profile.nickname },
            memberTarget: { item, index in
                BuddyMemberProfileTarget(
                    item: item,
                    source: profileSource,
                    role: index == 0 ? BuddyMemberCopy.roleAdmin : BuddyMemberCopy.roleMember
                )
            },
            isJoined: isJoined,
            joinTitle: "加入组织",
            leaveTitle: "退出组织",
            pinTitle: "置顶该组织",
            nicknameFieldTitle: "我在本组织的昵称",
            kind: .circle,
            onRequestJoin: { buddies.beginJoin(.circle(circle)) },
            onLeave: {
                messages.leaveCircleChat(circleID: circle.id, leaverName: app.user.name)
                buddies.leaveCircle(circle)
            },
            onEnterChat: { openCircleChat() },
            onInviteTap: { buddies.beginInvite(to: .circle(circle)) },
            onSearchTap: { toast = "演示：查找组织相关内容" },
            onReport: { toast = "已提交对「\(circle.name)」的投诉" },
            prefs: buddies.prefs(kind: .circle, name: circle.name),
            onPrefsChange: { next in
                buddies.updatePrefs(kind: .circle, name: circle.name) { $0 = next }
            },
            onMessageMember: { item in
                let greeting = "你好，我在「\(circle.name)」看到你，想认识一下。"
                if let convo = app.startDirectChat(with: item.profile.nickname, greeting: greeting) {
                    app.openMessages(conversationID: convo.id)
                }
            }
        )
        .platformSecondaryPage()
        .buddyOrgJoinChrome(
            buddies: buddies,
            openConversation: { app.openMessages(conversationID: $0) }
        )
        .platformTransientFeedback($toast)
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
                        HStack(spacing: 12) {
                            Image(systemName: guild.systemImage)
                                .font(.title3)
                                .foregroundStyle(PlatformStatus.warning)
                                .frame(width: 36, height: 36)
                                .background(
                                    PlatformStatus.warning.opacity(0.12),
                                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
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
        .platformSecondaryPage()
        .navigationDestination(for: CompanionGuild.self) { guild in
            BuddyGuildDetailView(guild: guild)
        }
    }
}
