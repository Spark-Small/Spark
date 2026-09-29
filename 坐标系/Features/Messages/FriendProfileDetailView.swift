//
//  FriendProfileDetailView.swift
//  坐标系
//
//  好友个人详情：发消息 / 音视频；更多里备注、分组、拉黑、投诉、删除。
//  朋友圈式配图 + 社区发图动态。
//

import SwiftUI
import CoordinateModels

struct FriendProfileDetailView: View {
    let nickname: String

    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(CommunityModel.self) private var community
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var showRemarkEditor = false
    @State private var showGroupPicker = false
    @State private var showReport = false
    @State private var confirmBlock = false
    @State private var confirmDelete = false
    @State private var feedback: String?
    @State private var remarkDraft = ""
    @State private var photoViewer: CommunityPhotoDestination?
    @State private var selectedPostID: CommunityPost.ID?
    @State private var chatSheet: PeerChatRoute?

    private var buddyItem: DiscoverBuddyItem? { buddies.item(for: nickname) }
    private var profile: BuddyProfile? { buddyItem?.profile }
    private var displayName: String { model.displayName(for: nickname) }
    private var remark: String { model.remark(for: nickname) }
    private var group: String { model.group(for: nickname) }

    private var authorPosts: [CommunityPost] {
        community.posts
            .filter { $0.author.caseInsensitiveCompare(nickname) == .orderedSame }
            .sorted { $0.postedAt > $1.postedAt }
    }

    /// 朋友圈缩略图：社区发图优先，不足时用搭子相册补齐
    private var momentsPhotos: [CommunityPhotoRef] {
        var seen = Set<CommunityPhotoRef>()
        var result: [CommunityPhotoRef] = []

        func append(_ refs: [CommunityPhotoRef]) {
            for ref in refs where seen.insert(ref).inserted {
                result.append(ref)
                if result.count >= 9 { return }
            }
        }

        for post in authorPosts {
            append(post.displayPhotos)
            if result.count >= 9 { break }
        }
        if result.count < 9, let profile {
            append(profile.photoRefs)
        }
        return result
    }

    private var postsWithPhotos: [CommunityPost] {
        authorPosts.filter { !$0.displayPhotos.isEmpty }
    }

    var body: some View {
        List {
            Section {
                header
                    .platformConversationListRowChrome()
            }

            TrustPublicProfileSections(
                nickname: nickname,
                currentUserName: app.user.name,
                buddyItem: buddyItem,
                compact: false
            )

            Section {
                LabeledContent(MessagesCopy.friendNicknameLabel, value: nickname)
                    .platformConversationListRowChrome()
                LabeledContent(
                    "UID",
                    value: UserPublicID.formatDisplay(UserPublicDirectory.uid(forNickname: nickname))
                )
                .textSelection(.enabled)
                .platformConversationListRowChrome()
                LabeledContent(
                    MessagesCopy.friendRemarkLabel,
                    value: remark.isEmpty ? MessagesCopy.friendRemarkPlaceholder : remark
                )
                .platformConversationListRowChrome()
                LabeledContent(MessagesCopy.friendGroupLabel, value: group)
                    .platformConversationListRowChrome()
            }

            Section {
                if momentsPhotos.isEmpty {
                    Text(MessagesCopy.friendMomentsEmpty)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .platformConversationListRowChrome()
                } else {
                    FriendMomentsPhotoGrid(photos: momentsPhotos) { index in
                        photoViewer = CommunityPhotoDestination(photos: momentsPhotos, startIndex: index)
                    }
                    .listRowBackground(Color.clear)
                    .platformConversationListRowChrome()
                    .accessibilityLabel(MessagesCopy.friendMomentsSection)
                }
            } header: {
                PlatformMessagesSectionHeader(title: MessagesCopy.friendMomentsSection)
            }

            Section {
                if postsWithPhotos.isEmpty {
                    Text(MessagesCopy.friendCommunityPostsEmpty)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .platformConversationListRowChrome()
                } else {
                    ForEach(postsWithPhotos.prefix(6)) { post in
                        Button {
                            selectedPostID = post.id
                        } label: {
                            FriendCommunityPostRow(post: post)
                        }
                        .buttonStyle(.plain)
                        .platformConversationListRowChrome()
                    }
                }
            } header: {
                PlatformMessagesSectionHeader(title: MessagesCopy.friendCommunityPosts)
            }

            if let profile {
                Section {
                    Text(profile.bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .platformConversationListRowChrome()
                } header: {
                    PlatformMessagesSectionHeader(title: "简介")
                }
                if !profile.tags.isEmpty {
                    Section {
                        TagFlow(tags: profile.tags)
                            .platformConversationListRowChrome()
                    } header: {
                        PlatformMessagesSectionHeader(title: "兴趣")
                    }
                }
            }
        }
        .platformConversationListChrome()
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(MessagesCopy.friendEditRemark, systemImage: "pencil") {
                        remarkDraft = remark
                        showRemarkEditor = true
                    }
                    Button(MessagesCopy.friendSetGroup, systemImage: "person.2") {
                        showGroupPicker = true
                    }
                    Button(MessagesCopy.friendAddToBlacklist, systemImage: "hand.raised", role: .destructive) {
                        confirmBlock = true
                    }
                    Button(MessagesCopy.friendComplaint, systemImage: "exclamationmark.bubble") {
                        showReport = true
                    }
                    Button(MessagesCopy.friendDelete, systemImage: "person.badge.minus", role: .destructive) {
                        confirmDelete = true
                    }
                } label: {
                    Label(MessagesCopy.more, systemImage: "ellipsis")
                }
            }
        }
        .platformDetailBottomBar {
            FriendProfileActionBar(
                onMessage: openChat,
                onCall: {
                    guard let conversation = app.startDirectChat(with: nickname, deliverGreeting: false),
                          let call = model.startVoiceCall(in: conversation.id)
                    else { return }
                    app.openMessages(conversationID: conversation.id, callID: call.id)
                    dismiss()
                }
            )
        }
        .sheet(item: $chatSheet) { route in
            NavigationStack {
                ConversationDetailView(
                    conversationID: route.conversationID,
                    chatContext: route.chatContext
                )
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .communityPhotoCover($photoViewer)
        .sheet(isPresented: Binding(
            get: { selectedPostID != nil },
            set: { if !$0 { selectedPostID = nil } }
        )) {
            if let selectedPostID {
                NavigationStack {
                    CommunityPostDetailView(postID: selectedPostID)
                        .platformSheetConfirmationToolbar()
                }
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.browser)
            }
        }
        .sheet(isPresented: $showRemarkEditor) {
            NavigationStack {
                List {
                    Section {
                        TextField(MessagesCopy.friendRemarkPlaceholder, text: $remarkDraft)
                            .textInputAutocapitalization(.never)
                            .platformConversationListRowChrome()
                    } header: {
                        PlatformMessagesSectionHeader(title: MessagesCopy.friendRemarkLabel)
                    }
                }
                .platformConversationListChrome()
                .navigationTitle(MessagesCopy.friendEditRemark)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarVisibility(.hidden, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(MessagesCopy.cancel) { showRemarkEditor = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MessagesCopy.friendSave) {
                            model.setRemark(remarkDraft, for: nickname)
                            showRemarkEditor = false
                        }
                    }
                }
            }
            .platformSheet(.browser)
        }
        .sheet(isPresented: $showGroupPicker) {
            NavigationStack {
                List {
                    ForEach(MessagesCopy.friendGroupOptions, id: \.self) { option in
                        Button {
                            model.setGroup(option, for: nickname)
                            showGroupPicker = false
                        } label: {
                            HStack {
                                Text(option)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                                if group == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                        .platformConversationListRowChrome()
                    }
                }
                .platformConversationListChrome()
                .navigationTitle(MessagesCopy.friendSetGroup)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarVisibility(.hidden, for: .tabBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(MessagesCopy.cancel) { showGroupPicker = false }
                    }
                }
            }
            .platformSheet(.browser)
        }
        .alert(
            "\(MessagesCopy.reportTitle)：\(nickname)",
            isPresented: $showReport
        ) {
            ForEach(MessagesCopy.reportReasons, id: \.self) { reason in
                Button(reason, role: .destructive) {
                    app.addModerationTicket(
                        postID: UUID(),
                        title: nickname,
                        reason: reason,
                        targetKind: .person
                    )
                    feedback = MessagesCopy.reportSubmitted
                }
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(MessagesCopy.reportFooter)
        }
        .alert(
            MessagesCopy.friendBlockConfirmTitle,
            isPresented: $confirmBlock
        ) {
            Button(MessagesCopy.friendAddToBlacklist, role: .destructive) {
                app.blockUser(nickname)
                feedback = MessagesCopy.friendBlocked
                dismiss()
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(MessagesCopy.friendBlockConfirmMessage)
        }
        .confirmationDialog(
            MessagesCopy.friendDeleteConfirmTitle,
            isPresented: $confirmDelete,
            titleVisibility: .visible
        ) {
            Button(MessagesCopy.friendDelete, role: .destructive) {
                model.deleteFriend(named: nickname)
                dismiss()
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(MessagesCopy.friendDeleteConfirmMessage)
        }
        .platformFeedbackAlert($feedback)
    }

    private func openChat() {
        let context: ConversationChatContext = {
            if let buddyItem { return .forBuddyItem(buddyItem) }
            return .communityAuthor
        }()
        guard let convo = app.startDirectChat(with: nickname, deliverGreeting: false) else { return }
        chatSheet = PeerChatRoute(conversationID: convo.id, chatContext: context)
    }

    private var header: some View {
        let flags = TrustPublicCredentials.flags(
            nickname: nickname,
            currentUserName: app.user.name,
            buddyItem: buddyItem,
            membershipActive: false,
            verificationPhotos: nickname.caseInsensitiveCompare(app.user.name) == .orderedSame
                ? app.user.verificationPhotos
                : []
        )
        return Label {
            VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                Text(displayName)
                    .font(.body.weight(.semibold))
                if !remark.isEmpty, displayName != nickname {
                    Text(nickname)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                TrustCredentialBadgeStrip(
                    photoVerified: flags.photoVerified,
                    isMember: false,
                    revealLocked: false
                )
                if let profile {
                    Text(profile.metricsText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        } icon: {
            PlatformSystemAvatar()
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Moments grid / post row

private struct FriendMomentsPhotoGrid: View {
    let photos: [CommunityPhotoRef]
    var onSelect: (Int) -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
        count: 3
    )

    var body: some View {
        LazyVGrid(columns: columns, spacing: PlatformMetrics.minContentGap) {
            ForEach(Array(photos.enumerated()), id: \.offset) { index, ref in
                Button {
                    onSelect(index)
                } label: {
                    CommunityRemotePhoto(ref: ref)
                        .aspectRatio(1, contentMode: .fill)
                        .clipShape(PlatformMetrics.mediaShape)
                        .contentShape(PlatformMetrics.mediaShape)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(MessagesCopy.friendSeePost)
            }
        }
    }
}

private struct FriendCommunityPostRow: View {
    let post: CommunityPost

    var body: some View {
        PlatformConversationRow(
            title: post.messageText,
            subtitle: post.author,
            time: post.postedAt
        )
        .accessibilityHint(MessagesCopy.friendSeePost)
    }
}

private struct FriendProfileActionBar: View {
    var onMessage: () -> Void
    var onCall: () -> Void

    var body: some View {
        DetailBottomActionBar {
            Button(MessagesCopy.friendSendMessage, systemImage: "message.fill", action: onMessage)
                .activityDetailBottomPrimaryCTA()

            Button(MessagesCopy.friendAVCall, systemImage: "video", action: onCall)
                .activityDetailBottomSecondaryCTA()
        }
        .labelStyle(.titleAndIcon)
    }
}
