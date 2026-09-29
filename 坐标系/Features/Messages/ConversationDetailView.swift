//
//  ConversationDetailView.swift
//  坐标系
//
//  会话详情编排：持有 @State，组合 Thread / Composer / Toolbar / MoreMenu。
//

import PhotosUI
import SwiftUI
import CoordinateModels

struct ConversationDetailView: View {
    let conversationID: ChatConversation.ID
    var focusMessageID: ChatMessage.ID? = nil
    var pendingCallID: CallSessionRecord.ID? = nil
    var chatContext: ConversationChatContext? = nil
    var onOpenCircleInfo: ((InterestCircle) -> Void)? = nil

    @Environment(MessagesModel.self) var model
    @Environment(BuddiesModel.self) var buddies
    @Environment(ActivitiesModel.self) var activities
    @Environment(AppModel.self) var app
    @Environment(\.dismiss) var dismiss

    @State var draft = ""
    @FocusState var isComposerFocused: Bool
    @State var copyFeedback: String?
    @State var sendPulse = 0
    @State var likePulse = 0
    @State var replyTo: ChatMessage?
    @State var selectedBuddy: DiscoverBuddyItem?
    @State var selectedActivity: Activity?
    @State var selectedPostID: CommunityPost.ID?
    @State var showGroupManage = false
    @State var showTransfer = false
    @State var showReport = false
    @State var confirmBlock = false
    @State var confirmLeaveCircle = false
    @State var showLocationPicker = false
    @State var locationDraft = ""
    @State var locationLatitude: Double?
    @State var locationLongitude: Double?
    @State var photoPickerItem: PhotosPickerItem?
    @State var mentionDraft: String?
    @State var pendingScrollMessageID: ChatMessage.ID?
    @State var activeCallID: UUID?
    @State var showCallHistory = false

    var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
    }

    var messages: [ChatMessage] {
        guard let conversation else { return model.messages(for: conversationID) }
        return model.displayedMessages(
            for: conversationID,
            viewerName: app.user.name,
            ownerName: conversation.ownerName
        )
    }

    var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isOutboundBlocked
    }

    var isOutboundBlocked: Bool {
        guard chatContext != nil else { return false }
        guard !model.hasPeerReply(in: conversationID) else { return false }
        return model.trailingOutboundCount(for: conversationID)
            >= ConversationChatContext.coldOutreachLimit
    }

    var composerEnabled: Bool {
        guard let conversation else { return false }
        return conversation.kind != .notice && !isOutboundBlocked
    }

    var quickReplyTemplates: [(label: String, text: String)] {
        guard let chatContext else { return [] }
        return chatContext.quickReplies(
            peerName: conversation?.title ?? "",
            activities: activities,
            currentUser: app.user
        )
    }

    var quickReplySectionTitle: String {
        chatContext?.quickReplySectionTitle ?? MessagesCopy.quickReplySectionTitle
    }

    var body: some View {
        Group {
            if let conversation {
                chatBody(conversation)
            } else {
                Color.clear
                    .onAppear { dismiss() }
            }
        }
        .onChange(of: model.conversations.map(\.id)) { _, ids in
            if !ids.contains(conversationID) { dismiss() }
        }
    }

    @ViewBuilder
    private func chatBody(_ conversation: ChatConversation) -> some View {
        let timeline = ChatTimelineItem.build(
            from: messages,
            isGroup: conversation.isGroup,
            isNotice: conversation.kind == .notice
        )
        let canLoadOlder = model.hasOlderMessages(
            in: conversationID,
            viewerName: app.user.name,
            ownerName: conversation.ownerName
        )

        ConversationThreadView(
            peerName: conversation.title,
            timeline: timeline,
            isEmpty: messages.isEmpty,
            canLoadOlder: canLoadOlder,
            messageCount: messages.count,
            messageIDs: messages.map(\.id),
            focusMessageID: focusMessageID,
            pendingScrollMessageID: $pendingScrollMessageID,
            onLoadOlder: { model.loadOlderMessages(in: conversationID) },
            onAppearThread: { handleThreadAppear(conversation: conversation) },
            onDisappearThread: handleThreadDisappear,
            onMessageIDsChanged: { ids in
                if let replyTo, !ids.contains(replyTo.id) {
                    self.replyTo = nil
                }
            }
        ) { message, chrome in
            ConversationMessageRow(
                message: message,
                chrome: chrome,
                conversationKind: conversation.kind,
                currentUserName: app.user.name,
                onTapAvatar: {
                    if message.isMe { return }
                    if conversation.kind == .direct {
                        selectedBuddy = buddies.item(for: conversation.title)
                    } else {
                        selectedBuddy = buddies.item(for: message.sender)
                    }
                },
                onToggleLike: {
                    model.toggleLike(messageID: message.id, in: conversationID)
                    likePulse += 1
                },
                onReply: {
                    replyTo = message
                    isComposerFocused = true
                },
                onOpenActivity: { id in
                    selectedActivity = activities.activity(id: id)
                },
                onOpenLink: openLink,
                onRetrySend: {
                    _ = model.retrySend(messageID: message.id, in: conversationID)
                },
                onSetReaction: { emoji in
                    model.setReaction(emoji, on: message.id, in: conversationID)
                },
                onDelete: {
                    if replyTo?.id == message.id { replyTo = nil }
                    model.deleteMessage(messageID: message.id, in: conversationID)
                },
                onCopied: { copyFeedback = MessagesCopy.copied }
            )
        }
        .background(PlatformSurface.canvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                ConversationDetailToolbarTitle(
                    conversation: conversation,
                    viewerName: app.user.name,
                    onTap: toolbarTapAction(for: conversation)
                )
            }
            if conversation.kind != .notice {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(MessagesCopy.voiceCall, systemImage: "phone") {
                        activeCallID = model.startVoiceCall(in: conversation.id)?.id
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(MessagesCopy.videoCall, systemImage: "video") {
                        activeCallID = model.startVideoCall(in: conversation.id)?.id
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                moreMenu(for: conversation)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ConversationComposerSection(
                conversation: conversation,
                draft: $draft,
                isComposerFocused: $isComposerFocused,
                mentionDraft: $mentionDraft,
                replyTo: replyTo,
                isOutboundBlocked: isOutboundBlocked,
                composerEnabled: composerEnabled,
                canSend: canSend,
                quickReplySectionTitle: quickReplySectionTitle,
                quickReplyTemplates: quickReplyTemplates,
                memberNamesExcludingSelf: conversation.memberNames.filter { $0 != app.user.name },
                onCancelReply: { replyTo = nil },
                onVoice: {
                    _ = model.sendVoice(duration: Double.random(in: 2...12), to: conversation.id)
                    sendPulse += 1
                },
                onSend: { send(to: conversation.id) },
                onQuickReply: { sendQuickReply($0, to: conversation.id) }
            ) {
                attachMenu(for: conversation)
            }
        }
        .onChange(of: photoPickerItem) { _, item in
            Task { await loadAndSendPhoto(item, conversationID: conversation.id) }
        }
        .sheet(isPresented: $showGroupManage) {
            GroupManageSheet(conversationID: conversationID) { activity in
                selectedActivity = activity
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showTransfer) {
            ChatTransferSheet { amount in
                guard model.sendTransfer(
                    amount: amount,
                    to: conversation.id,
                    currentUserName: app.user.name
                ) != nil else { return false }
                sendPulse += 1
                return true
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .sheet(isPresented: $showCallHistory) {
            CallHistorySheet(conversationID: conversationID) { kind in
                switch kind {
                case .voice:
                    activeCallID = model.startVoiceCall(in: conversationID)?.id
                case .video:
                    activeCallID = model.startVideoCall(in: conversationID)?.id
                }
            }
            .toolbarVisibility(.hidden, for: .tabBar)
        }
        .fullScreenCover(isPresented: Binding(
            get: { activeCallID != nil },
            set: { if !$0 { activeCallID = nil } }
        )) {
            if let activeCallID {
                CallSessionView(conversationID: conversation.id, callID: activeCallID)
            }
        }
        .sheet(isPresented: $showLocationPicker) {
            ActivityMapPickerSheet(
                locationText: $locationDraft,
                latitude: $locationLatitude,
                longitude: $locationLongitude
            )
            .toolbarVisibility(.hidden, for: .tabBar)
            .onDisappear {
                guard let lat = locationLatitude, let lon = locationLongitude else { return }
                let name = locationDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                _ = model.sendLocation(
                    name: name.isEmpty ? MessagesCopy.mapLocationFallback : name,
                    latitude: lat,
                    longitude: lon,
                    to: conversation.id
                )
                sendPulse += 1
                locationLatitude = nil
                locationLongitude = nil
            }
        }
        .alert(
            "\(MessagesCopy.reportTitle)：\(conversation.title)",
            isPresented: $showReport
        ) {
            ForEach(MessagesCopy.reportReasons, id: \.self) { reason in
                Button(reason, role: .destructive) {
                    app.addModerationTicket(
                        postID: conversation.id,
                        title: conversation.title,
                        reason: reason,
                        targetKind: .conversation
                    )
                    copyFeedback = MessagesCopy.reportSubmitted
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
            Button(MessagesCopy.blockUser, role: .destructive) {
                app.blockUser(conversation.title)
                copyFeedback = MessagesCopy.blockedAndRemoved
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text(MessagesCopy.friendBlockConfirmMessage)
        }
        .alert(
            "退出圈子？",
            isPresented: $confirmLeaveCircle
        ) {
            Button(MessagesCopy.leaveGroup, role: .destructive) {
                leaveCircleGroupIfPossible()
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text("退出后将离开圈子群聊，成员设置会清除，可随时重新加入。")
        }
        .sensoryFeedback(.success, trigger: sendPulse)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: likePulse)
        .platformFeedbackAlert($copyFeedback)
        .alert(
            MessagesCopy.deleteDialogTitle,
            isPresented: Binding(
                get: { model.conversationPendingDelete?.id == conversationID },
                set: { if !$0 { model.cancelDelete() } }
            )
        ) {
            Button(MessagesCopy.deleteDialogConfirm, role: .destructive, action: model.confirmDelete)
            Button(MessagesCopy.deleteDialogCancel, role: .cancel, action: model.cancelDelete)
        } message: {
            Text(MessagesCopy.deleteDialogMessage(title: conversation.title))
        }
        .sheet(item: $selectedBuddy) { item in
            NavigationStack {
                BuddyDetailRouteView(item: item)
                    .platformSheetConfirmationToolbar()
            }
            .toolbarVisibility(.hidden, for: .tabBar)
            .platformSheet(.browser)
        }
        .sheet(item: $selectedActivity) { activity in
            ActivityBrowserSheet(activity: activity)
                .toolbarVisibility(.hidden, for: .tabBar)
                .platformSheet(.browser)
        }
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
    }

    @ViewBuilder
    private func moreMenu(for conversation: ChatConversation) -> some View {
        ConversationDetailMoreMenu(
            conversation: conversation,
            isOwnedByViewer: conversation.isOwned(by: app.user.name),
            hasBuddyProfile: buddies.item(for: conversation.title) != nil,
            hasRelatedActivity: relatedActivity(for: conversation) != nil,
            hasCircleInfo: circleForConversation(conversation) != nil,
            onTogglePin: { model.togglePin(conversation.id) },
            onToggleMute: { model.toggleMute(conversation.id) },
            onCallHistory: { showCallHistory = true },
            onCircleInfo: {
                if let circle = circleForConversation(conversation) {
                    onOpenCircleInfo?(circle)
                }
            },
            onGroupManage: { showGroupManage = true },
            onActivityDetail: { selectedActivity = relatedActivity(for: conversation) },
            onViewProfile: { selectedBuddy = buddies.item(for: conversation.title) },
            onReport: { showReport = true },
            onBlock: { confirmBlock = true },
            onDissolveOrLeave: { model.requestDelete(conversation) },
            onCancelRegistration: {
                if let activityID = conversation.relatedActivityID {
                    app.cancelActivityRegistration(activityID)
                    dismiss()
                } else {
                    model.requestDelete(conversation)
                }
            },
            onLeaveCircle: { confirmLeaveCircle = true },
            onDeleteConversation: { model.requestDelete(conversation) }
        )
    }

    @ViewBuilder
    private func attachMenu(for conversation: ChatConversation) -> some View {
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Label(MessagesCopy.attachCamera, systemImage: "camera.fill")
        }
        PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Label(MessagesCopy.attachPhoto, systemImage: "photo")
        }
        Button(MessagesCopy.attachSticker, systemImage: "face.smiling") {
            _ = model.sendSticker(
                ["👍", "🎉", "🔥", "😎"].randomElement()!,
                to: conversation.id
            )
            sendPulse += 1
        }
        Button(MessagesCopy.attachLocation, systemImage: "mappin.and.ellipse") {
            locationDraft = app.user.city.isEmpty
                ? MessagesCopy.currentLocation
                : app.user.city
            locationLatitude = nil
            locationLongitude = nil
            showLocationPicker = true
        }
        if let activity = relatedActivity(for: conversation)
            ?? activities.inviteableActivities.first {
            Button(MessagesCopy.attachActivity, systemImage: "calendar") {
                _ = model.sendActivityCard(activity, to: conversation.id)
                sendPulse += 1
            }
        }
        Button(MessagesCopy.attachTransfer, systemImage: "yensign.circle") {
            showTransfer = true
        }
        if conversation.isGroup {
            Button(MessagesCopy.mentionMembers, systemImage: "at") {
                mentionDraft = ""
            }
        }
    }
}

#Preview("活动群聊天") {
    let app = AppModel.preview
    NavigationStack {
        ConversationDetailView(conversationID: SampleData.conversations[0].id)
    }
    .environment(app)
    .environment(app.messages)
    .environment(app.buddies)
    .environment(app.activities)
}
