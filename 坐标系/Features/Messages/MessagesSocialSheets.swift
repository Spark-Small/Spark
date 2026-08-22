//
//  MessagesSocialSheets.swift
//  坐标系
//
//  群管理 / 好友申请 / 举报 / 转账。
//

import SwiftUI

// MARK: - Group manage

struct GroupManageSheet: View {
    let conversationID: ChatConversation.ID
    var onOpenActivity: (Activity) -> Void

    @Environment(MessagesModel.self) private var model
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var announcementDraft = ""
    @State private var renameDraft = ""
    @State private var showMemberPicker = false
    @State private var showAllMembers = false
    @State private var pendingKickMember: String?

    private let memberColumns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.cardInfoSpacing),
        count: 5
    )

    private var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
    }

    private var members: [GroupMemberRecord] {
        model.groupMembers(for: conversationID)
    }

    private var isOwner: Bool {
        conversation?.isOwned(by: app.user.name) == true
    }

    private var myRole: GroupMemberRole {
        model.role(of: app.user.name, in: conversationID)
    }

    private var canManageMembers: Bool {
        isOwner || myRole.canManageMembers
    }

    private var sheetTitle: String {
        "\(MessagesCopy.groupManage) (\(members.count))"
    }

    private var trimmedRenameDraft: String {
        renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSaveRename: Bool {
        guard isOwner, !trimmedRenameDraft.isEmpty else { return false }
        return trimmedRenameDraft.caseInsensitiveCompare(conversation?.title ?? "") != .orderedSame
    }

    private var visibleMembers: [GroupMemberRecord] {
        showAllMembers ? members : Array(members.prefix(9))
    }

    private var canExpandMembers: Bool {
        members.count > 9
    }

    var body: some View {
        NavigationStack {
            List {
                if let conversation {
                    membersSection
                    groupInfoSection(conversation)
                    announcementSection
                    activitySection(conversation)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
            .navigationTitle(sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.close) { dismiss() }
                }
                if canSaveRename {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MessagesCopy.groupSaveName) {
                            saveRename()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear(perform: syncDrafts)
            .onChange(of: conversation?.title) { _, _ in
                syncRenameDraft()
            }
            .onChange(of: conversation?.announcement) { _, _ in
                syncAnnouncementDraft()
            }
        }
        .platformSheet(.form)
        .sheet(isPresented: $showMemberPicker) {
            GroupMemberPickerSheet(conversationID: conversationID)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
        .confirmationDialog(
            "移出群聊？",
            isPresented: Binding(
                get: { pendingKickMember != nil },
                set: { if !$0 { pendingKickMember = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(MessagesCopy.groupKick, role: .destructive) {
                if let nickname = pendingKickMember {
                    model.kickMember(nickname, from: conversationID)
                }
                pendingKickMember = nil
            }
            Button(MessagesCopy.cancel, role: .cancel) {
                pendingKickMember = nil
            }
        } message: {
            if let nickname = pendingKickMember {
                Text("将 \(nickname) 移出当前群聊。")
            }
        }
    }

    private func syncDrafts() {
        syncRenameDraft()
        syncAnnouncementDraft()
    }

    private func syncRenameDraft() {
        renameDraft = conversation?.title ?? ""
    }

    private func syncAnnouncementDraft() {
        announcementDraft = conversation?.announcement ?? ""
    }

    private func saveRename() {
        guard canSaveRename else { return }
        model.renameGroup(trimmedRenameDraft, for: conversationID)
        syncRenameDraft()
    }

    private func publishAnnouncement() {
        let trimmed = announcementDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.updateAnnouncement(trimmed, for: conversationID)
        syncAnnouncementDraft()
    }

    // MARK: - Members

    @ViewBuilder
    private var membersSection: some View {
        Section {
            LazyVGrid(columns: memberColumns, spacing: PlatformMetrics.cardInfoSpacing) {
                ForEach(visibleMembers) { member in
                    memberCell(member)
                }
                if isOwner {
                    inviteMemberCell
                }
            }
            .padding(.vertical, PlatformMetrics.formRowVerticalPadding)

            if canExpandMembers, !showAllMembers {
                Button {
                    withAnimation(.snappy) { showAllMembers = true }
                } label: {
                    HStack {
                        Spacer()
                        Text(BuddyMemberCopy.moreMembers)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }

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
        } header: {
            Text(MessagesCopy.groupMembersSection)
        }
    }

    @ViewBuilder
    private func memberCell(_ member: GroupMemberRecord) -> some View {
        let label = truncated(member.nickname)
        let roleCaption = member.role == .member ? nil : member.role.rawValue
        let canManageMember = canManageMembers
            && member.nickname.caseInsensitiveCompare(app.user.name) != .orderedSame
            && member.role != .owner

        let cell = VStack(spacing: PlatformMetrics.detailMicroSpacing) {
            PlatformListAvatarView(name: member.nickname, side: 52)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(maxWidth: 56)
            if let roleCaption {
                Text(roleCaption)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(
            roleCaption.map { "\(member.nickname)，\($0)" } ?? member.nickname
        )

        if canManageMember {
            cell.contextMenu {
                memberManagementActions(for: member)
            }
        } else {
            cell
        }
    }

    @ViewBuilder
    private func memberManagementActions(for member: GroupMemberRecord) -> some View {
        if canManageMembers,
           member.nickname.caseInsensitiveCompare(app.user.name) != .orderedSame,
           member.role != .owner {
            if isOwner {
                if member.role == .admin {
                    Button(MessagesCopy.groupRemoveAdmin) {
                        model.removeGroupAdmin(member.nickname, in: conversationID)
                    }
                } else if member.role == .member {
                    Button(MessagesCopy.groupSetAdmin) {
                        model.addGroupAdmin(member.nickname, in: conversationID)
                    }
                    .disabled(members.filter { $0.role == .admin }.count >= 3)
                }
            }
            Button(MessagesCopy.groupKick, role: .destructive) {
                pendingKickMember = member.nickname
            }
        }
    }

    private var inviteMemberCell: some View {
        Button {
            showMemberPicker = true
        } label: {
            VStack(spacing: PlatformMetrics.detailMicroSpacing) {
                RoundedRectangle(cornerRadius: PlatformMetrics.radiusMedia, style: .continuous)
                    .strokeBorder(.quaternary, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.title3.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                Text(MessagesCopy.add)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MessagesCopy.groupInviteMembers)
    }

    // MARK: - Info / announcement / owner

    @ViewBuilder
    private func groupInfoSection(_ conversation: ChatConversation) -> some View {
        Section {
            if isOwner {
                TextField(MessagesCopy.groupNameLabel, text: $renameDraft)
            } else {
                LabeledContent(MessagesCopy.groupNameLabel, value: conversation.title)
            }
            if let owner = conversation.ownerName {
                LabeledContent(MessagesCopy.groupOwnerBadge, value: owner)
            }
        } header: {
            Text(MessagesCopy.groupInfoSection)
        }
    }

    @ViewBuilder
    private var announcementSection: some View {
        Section {
            if let announcement = conversation?.announcement, !announcement.isEmpty {
                Text(announcement)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else if !isOwner {
                Text(MessagesCopy.groupAnnouncementEmpty)
                    .foregroundStyle(.tertiary)
            }

            if isOwner {
                TextField(MessagesCopy.groupAnnouncementPlaceholder, text: $announcementDraft, axis: .vertical)
                    .lineLimit(2...4)

                Button(MessagesCopy.groupPublishAnnouncement) {
                    publishAnnouncement()
                }
                .disabled(announcementDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        } header: {
            Text(MessagesCopy.groupAnnouncementSection)
        } footer: {
            if isOwner {
                Text("发布后，成员会在群聊内看到最新公告。")
            }
        }
    }

    @ViewBuilder
    private func activitySection(_ conversation: ChatConversation) -> some View {
        if let activityID = conversation.relatedActivityID,
           let activity = activities.activity(id: activityID) {
            Section {
                Button {
                    dismiss()
                    onOpenActivity(activity)
                } label: {
                    Label(MessagesCopy.groupOpenActivity, systemImage: "calendar")
                }
            }
        }
    }

    private func truncated(_ name: String) -> String {
        if name.count <= 4 { return name }
        return String(name.prefix(3)) + "…"
    }
}

// MARK: - Friend requests / Message requests

struct MessageRequestsSheet: View {
    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var onOpen: (ChatConversation) -> Void
    @State private var previewConversation: ChatConversation?

    private var pendingFriendRequests: [FriendRequest] {
        model.friendRequests.filter { $0.status == .pending }
    }

    var body: some View {
        MessagesFormSheet(title: MessagesCopy.messageRequestsTitle) {
            List {
                if !pendingFriendRequests.isEmpty {
                    Section(MessagesCopy.friendRequestsSection) {
                        ForEach(pendingFriendRequests) { request in
                            MessageRequestPreviewRow(
                                title: request.fromName,
                                subtitle: request.message
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(MessagesCopy.accept) {
                                    acceptFriendRequest(request)
                                }
                                .tint(.accentColor)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(MessagesCopy.ignore, role: .destructive) {
                                    model.declineFriendRequest(request.id)
                                }
                            }
                        }
                    }
                }

                Section(MessagesCopy.messageRequestsSection) {
                    if model.messageRequests.isEmpty {
                        Text(MessagesCopy.messageRequestsEmpty)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(model.messageRequests) { conversation in
                            Button {
                                previewConversation = conversation
                            } label: {
                                MessageRequestPreviewRow(
                                    title: conversation.title,
                                    subtitle: model.requestPreview(for: conversation),
                                    badge: model.requestSourceLabel(for: conversation)
                                )
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(MessagesCopy.accept) {
                                    model.acceptMessageRequest(conversation.id)
                                    dismiss()
                                    onOpen(conversation)
                                }
                                .tint(.accentColor)
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(MessagesCopy.delete, role: .destructive) {
                                    model.declineMessageRequest(conversation.id)
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(item: $previewConversation) { conversation in
            NavigationStack {
                ConversationDetailView(conversationID: conversation.id)
            }
            .toolbarVisibility(.hidden, for: .tabBar)
            .platformSheet(.browser)
        }
    }

    private func acceptFriendRequest(_ request: FriendRequest) {
        let name = request.fromName
        model.acceptFriendRequest(request.id)
        if let convo = model.conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            dismiss()
            onOpen(convo)
        }
    }
}

// MARK: - Transfer

struct ChatTransferSheet: View {
    /// 返回是否发送成功（失败时 Sheet 留在原地提示）
    var onConfirm: (Double) -> Bool

    @Environment(WalletStore.self) private var wallet
    @Environment(\.dismiss) private var dismiss
    @State private var amountText = MessagesCopy.transferDefaultAmount
    @State private var errorMessage: String?

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    private var amountCents: Int {
        guard let amount else { return 0 }
        return WalletMoney.cents(fromYuan: amount)
    }

    var body: some View {
        MessagesFormSheet(title: MessagesCopy.transferTitle, dismissAction: .cancel) {
            List {
                Section {
                    TextField(MessagesCopy.transferAmountPlaceholder, text: $amountText)
                        .keyboardType(.decimalPad)
                    LabeledContent("钱包余额", value: wallet.balanceText)
                } header: {
                    Text(MessagesCopy.transferAmountHeader)
                } footer: {
                    Text(MessagesCopy.transferDemoFooter)
                }
                Section {
                    Button(MessagesCopy.transferConfirm) {
                        guard let amount, amount > 0 else { return }
                        if amountCents > wallet.balanceCents {
                            errorMessage = "余额不足，请先前往钱包充值。"
                            return
                        }
                        if onConfirm(amount) {
                            dismiss()
                        } else {
                            errorMessage = "转账失败，请稍后重试。"
                        }
                    }
                    .disabled(amount == nil || (amount ?? 0) <= 0)
                }
            }
            .alert("无法转账", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("好的", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }
}

// MARK: - Request row

/// 系统 insetGrouped 双行预览（无收件箱头像 / 自定义按钮行）。
private struct MessageRequestPreviewRow: View {
    let title: String
    let subtitle: String
    var badge: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
            HStack {
                Text(title)
                    .font(.body)
                if let badge, !badge.isEmpty {
                    Text(badge)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GroupMemberPickerSheet: View {
    let conversationID: ChatConversation.ID

    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var selectedNames: Set<String> = []

    private var candidates: [String] {
        MessagesContactRoster.nicknames(
            conversations: model.conversations,
            inviteNicknames: buddies.inviteRecords.map(\.nickname),
            bookingNicknames: buddies.bookingRecords.map(\.companionNickname),
            blockedNames: Array(app.blockedUserNames)
        )
        .filter { name in
            !model.groupMembers(for: conversationID).contains {
                $0.nickname.caseInsensitiveCompare(name) == .orderedSame
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(candidates, id: \.self) { name in
                        Button {
                            toggleSelection(name)
                        } label: {
                            HStack {
                                PlatformListAvatarView(name: name, side: 36)
                                Text(name)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                                if selectedNames.contains(name) {
                                    Image(systemName: "checkmark")
                                        .font(.body.weight(.semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                } footer: {
                    Text("邀请后，对方会收到进群通知。")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.visible)
            .navigationTitle(MessagesCopy.groupMemberPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MessagesCopy.groupInvite) {
                        model.inviteMembers(Array(selectedNames), to: conversationID)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedNames.isEmpty)
                }
            }
        }
        .platformSheet(.form)
    }

    private func toggleSelection(_ name: String) {
        if selectedNames.contains(name) {
            selectedNames.remove(name)
        } else {
            selectedNames.insert(name)
        }
    }
}
