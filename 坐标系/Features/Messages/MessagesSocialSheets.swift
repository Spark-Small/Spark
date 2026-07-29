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

    private var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
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

    var body: some View {
        MessagesBrowserSheet(title: MessagesCopy.groupManage) {
            List {
                if let conversation {
                    groupInfoSection(conversation)
                    announcementSection
                    membersSection(conversation)
                    if isOwner { ownerSection }
                    activitySection(conversation)
                }
            }
            .onAppear {
                renameDraft = conversation?.title ?? ""
                announcementDraft = conversation?.announcement ?? ""
            }
        }
        .sheet(isPresented: $showMemberPicker) {
            GroupMemberPickerSheet(conversationID: conversationID)
        }
    }

    @ViewBuilder
    private func groupInfoSection(_ conversation: ChatConversation) -> some View {
        Section {
            LabeledContent(MessagesCopy.groupNameLabel, value: conversation.title)
                .messagesListRow()
            if let owner = conversation.ownerName {
                LabeledContent(MessagesCopy.groupOwnerBadge, value: owner)
                    .messagesListRow()
            }
            LabeledContent(
                MessagesCopy.groupMembersLabel,
                value: MessagesCopy.groupMemberCount(conversation.memberNames.count)
            )
            .messagesListRow()
        } header: {
            PlatformMessagesSectionHeader(title: MessagesCopy.groupInfoSection)
        }
    }

    @ViewBuilder
    private var announcementSection: some View {
        Section {
            if let announcement = conversation?.announcement, !announcement.isEmpty {
                Text(announcement)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .messagesListRow()
            } else {
                Text(MessagesCopy.groupAnnouncementEmpty)
                    .foregroundStyle(.tertiary)
                    .messagesListRow()
            }
            if isOwner {
                TextField(MessagesCopy.groupAnnouncementPlaceholder, text: $announcementDraft, axis: .vertical)
                    .lineLimit(2...4)
                    .messagesListRow()
                Button(MessagesCopy.groupPublishAnnouncement) {
                    model.updateAnnouncement(announcementDraft, for: conversationID)
                    announcementDraft = ""
                }
                .disabled(announcementDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .messagesListRow()
            }
        } header: {
            PlatformMessagesSectionHeader(title: MessagesCopy.groupAnnouncementSection)
        }
    }

    @ViewBuilder
    private func membersSection(_ conversation: ChatConversation) -> some View {
        Section {
            ForEach(model.groupMembers(for: conversationID)) { member in
                LabeledContent {
                    if canManageMembers,
                       member.nickname.caseInsensitiveCompare(app.user.name) != .orderedSame,
                       member.role != .owner {
                        Menu {
                            if isOwner {
                                Button(
                                    member.role == .admin ? MessagesCopy.groupRemoveAdmin : MessagesCopy.groupSetAdmin
                                ) {
                                    model.updateMemberRole(
                                        member.nickname,
                                        role: member.role == .admin ? .member : .admin,
                                        in: conversationID
                                    )
                                }
                            }
                            Button(MessagesCopy.groupKick, role: .destructive) {
                                model.kickMember(member.nickname, from: conversationID)
                            }
                        } label: {
                            Text(member.role == .admin ? MessagesCopy.groupRemoveAdmin : MessagesCopy.groupRoleSection)
                                .font(.subheadline)
                        }
                    }
                } label: {
                    Label {
                        Text(member.nickname)
                    } icon: {
                        PlatformSystemAvatar()
                    }
                }
                .badge(member.role.rawValue)
                .messagesListRow()
            }
        } header: {
            PlatformMessagesSectionHeader(title: MessagesCopy.groupMembersSection)
        }
    }

    @ViewBuilder
    private var ownerSection: some View {
        Section {
            TextField(MessagesCopy.groupRenamePlaceholder, text: $renameDraft)
                .messagesListRow()
            Button(MessagesCopy.groupSaveName) {
                model.renameGroup(renameDraft, for: conversationID)
                renameDraft = ""
            }
            .disabled(renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .messagesListRow()

            Button(MessagesCopy.groupInviteMembers) {
                showMemberPicker = true
            }
            .messagesListRow()
        } header: {
            PlatformMessagesSectionHeader(title: MessagesCopy.groupOwnerSection)
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
                .messagesListRow()
            }
        }
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

// MARK: - Report

struct MessageReportSheet: View {
    let targetTitle: String
    var onSubmit: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason = MessagesCopy.reportReasons[0]

    var body: some View {
        MessagesFormSheet(title: MessagesCopy.reportTitle, dismissAction: .cancel) {
            List {
                Section {
                    Text(targetTitle)
                } header: {
                    Text(MessagesCopy.reportTargetSection)
                }
                Section {
                    Picker(MessagesCopy.reportReasonSection, selection: $reason) {
                        ForEach(MessagesCopy.reportReasons, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } header: {
                    Text(MessagesCopy.reportReasonSection)
                }
                Section {
                    Button(MessagesCopy.reportSubmit, role: .destructive) {
                        onSubmit(reason)
                        dismiss()
                    }
                } footer: {
                    Text(MessagesCopy.reportFooter)
                }
            }
        }
    }
}

// MARK: - Transfer

struct ChatTransferSheet: View {
    var onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = MessagesCopy.transferDefaultAmount

    private var amount: Double? {
        Double(amountText.replacingOccurrences(of: ",", with: "."))
    }

    var body: some View {
        MessagesFormSheet(title: MessagesCopy.transferTitle, dismissAction: .cancel) {
            List {
                Section {
                    TextField(MessagesCopy.transferAmountPlaceholder, text: $amountText)
                        .keyboardType(.decimalPad)
                } header: {
                    Text(MessagesCopy.transferAmountHeader)
                } footer: {
                    Text(MessagesCopy.transferDemoFooter)
                }
                Section {
                    Button(MessagesCopy.transferConfirm) {
                        guard let amount, amount > 0 else { return }
                        onConfirm(amount)
                        dismiss()
                    }
                    .disabled(amount == nil || (amount ?? 0) <= 0)
                }
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
                ForEach(Array(candidates.enumerated()), id: \.element) { _, name in
                    Button {
                        if selectedNames.contains(name) {
                            selectedNames.remove(name)
                        } else {
                            selectedNames.insert(name)
                        }
                    } label: {
                        HStack {
                            Text(name)
                            Spacer(minLength: 0)
                            if selectedNames.contains(name) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle(MessagesCopy.groupMemberPickerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(MessagesCopy.groupInvite) {
                        model.inviteMembers(Array(selectedNames), to: conversationID)
                        dismiss()
                    }
                    .disabled(selectedNames.isEmpty)
                }
            }
        }
        .platformSheet(.browser)
    }
}
