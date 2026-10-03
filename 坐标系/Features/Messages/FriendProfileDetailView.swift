//
//  FriendProfileDetailView.swift
//  坐标系
//
//  通讯录好友资料：顶栏标题「好友资料」；顶区身份 + 认证徽章按钮 + 社交与简介；
//  备注行内编辑、分组、信任档案、动态与主办场次。
//

import SwiftUI
import CoordinateModels

struct FriendProfileDetailView: View {
    enum MessageAction: Equatable {
        /// 打开私聊 Sheet（通讯录入口）
        case openChat
        /// 已在与对方的会话中：发消息 = 关闭资料回到聊天（信息联系人卡范式）
        case dismissToChat
    }

    let nickname: String
    var messageAction: MessageAction = .openChat

    // 跨文件 extension（+Presentations / +Header）需 internal。
    @Environment(MessagesModel.self) var model
    @Environment(BuddiesModel.self) var buddies
    @Environment(AppModel.self) var app
    @Environment(CommunityModel.self) var community
    @Environment(ActivitiesModel.self) var activities
    @Environment(MembershipStore.self) var membership
    @Environment(TrustService.self) var trust
    @Environment(PhotoVerificationStore.self) var photoVerification
    @Environment(\.dismiss) var dismiss

    @State var showGroupPicker = false
    @State var showReport = false
    @State var confirmBlock = false
    @State var confirmDelete = false
    @State var feedback: String?
    @State var remarkDraft = ""
    @State var chatSheet: PeerChatRoute?
    @FocusState var remarkFocused: Bool

    var buddyItem: DiscoverBuddyItem? { buddies.item(for: nickname) }
    var profile: BuddyProfile? { buddyItem?.profile }
    var displayName: String { model.displayName(for: nickname) }
    var remark: String { model.remark(for: nickname) }
    var group: String { model.group(for: nickname) }

    /// 有备注时展示名是备注；副行对照真实昵称。
    var showsNicknameAside: Bool {
        !remark.isEmpty && displayName.caseInsensitiveCompare(nickname) != .orderedSame
    }

    var bio: String {
        profile?.bio.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var tags: [String] { profile?.tags ?? [] }

    var trustFlags: TrustPublicCredentials.Flags {
        _ = photoVerification.isVerified
        return TrustPublicCredentials.flags(
            nickname: nickname,
            currentUserName: app.user.name,
            buddyItem: buddyItem,
            membershipActive: membership.isEntitled,
            verificationPhotos: nickname.caseInsensitiveCompare(app.user.name) == .orderedSame
                ? app.user.verificationPhotos
                : []
        )
    }

    var publicBadges: [TrustBadge] {
        _ = trust.revision
        let flags = trustFlags
        return trust.publicCard(
            for: nickname,
            currentUserName: app.user.name,
            buddyItem: buddyItem,
            signals: TrustPrivateSignals(
                profileRatio: 0.5,
                isMember: flags.isMember,
                isGuest: false,
                hasPhone: false,
                photoVerified: flags.photoVerified,
                accountCreatedAt: nil,
                friendCount: 0,
                liveHostedCount: hostedActivities.count
            )
        ).badges
    }

    var hostedActivities: [Activity] {
        activities.activities
            .filter { $0.hostName.caseInsensitiveCompare(nickname) == .orderedSame }
            .sorted { $0.date > $1.date }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        applyingFriendProfilePresentations(
            List {
                Section {
                    contactHeader
                }

                Section {
                    LabeledContent(
                        "UID",
                        value: UserPublicID.formatDisplay(UserPublicDirectory.uid(forNickname: nickname))
                    )
                    .textSelection(.enabled)

                    if let profile, !profile.city.isEmpty {
                        LabeledContent(MessagesCopy.friendCityLabel, value: profile.city)
                    }

                    if let looking = profile?.lookingFor.trimmingCharacters(in: .whitespacesAndNewlines),
                       !looking.isEmpty {
                        LabeledContent(MessagesCopy.friendLookingForLabel, value: looking)
                    }

                    LabeledContent(MessagesCopy.friendRemarkLabel) {
                        TextField(MessagesCopy.friendRemarkPlaceholder, text: $remarkDraft)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.never)
                            .submitLabel(.done)
                            .focused($remarkFocused)
                            .onSubmit { commitRemarkIfNeeded() }
                    }
                    .onAppear { syncRemarkDraft() }
                    .onChange(of: remarkFocused) { _, focused in
                        if !focused { commitRemarkIfNeeded() }
                    }
                    .onDisappear { commitRemarkIfNeeded() }

                    Button {
                        commitRemarkIfNeeded()
                        showGroupPicker = true
                    } label: {
                        LabeledContent(MessagesCopy.friendGroupLabel, value: group)
                            .foregroundStyle(.primary)
                    }
                } header: {
                    Text(MessagesCopy.friendContactSection)
                }

                TrustPublicProfileSections(
                    nickname: nickname,
                    currentUserName: app.user.name,
                    buddyItem: buddyItem,
                    liveHostedCount: hostedActivities.count,
                    compact: true
                )

                if !hostedActivities.isEmpty {
                    Section(MessagesCopy.friendHostedSection) {
                        ForEach(hostedActivities) { activity in
                            CommunityHostedActivityLinkRow(activity: activity)
                        }
                    }
                }

                CommunityAuthorRecentPostsSection(authorName: nickname)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(MessagesCopy.friendProfileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
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
                    onCall: startCall
                )
            }
        )
    }

    func openChat() {
        commitRemarkIfNeeded()
        switch messageAction {
        case .dismissToChat:
            dismiss()
        case .openChat:
            let context: ConversationChatContext = {
                if let buddyItem { return .forBuddyItem(buddyItem) }
                return .communityAuthor
            }()
            guard let convo = app.startDirectChat(with: nickname, deliverGreeting: false) else { return }
            chatSheet = PeerChatRoute(conversationID: convo.id, chatContext: context)
        }
    }

    func startCall() {
        commitRemarkIfNeeded()
        guard let conversation = app.startDirectChat(with: nickname, deliverGreeting: false),
              let call = model.startVoiceCall(in: conversation.id)
        else { return }
        app.openMessages(conversationID: conversation.id, callID: call.id)
        dismiss()
    }

    func syncRemarkDraft() {
        remarkDraft = remark
    }

    func commitRemarkIfNeeded() {
        let trimmed = remarkDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != remark else {
            remarkDraft = remark
            return
        }
        model.setRemark(remarkDraft, for: nickname)
        remarkDraft = model.remark(for: nickname)
    }
}
