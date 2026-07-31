//
//  ConversationDetailView.swift
//  坐标系
//
//  会话详情：系统信息式气泡线程（群聊对方头像；引用 / 点按时间 / 双击喜欢）。
//

import SwiftUI
import PhotosUI
import UIKit

struct ConversationDetailView: View {
    let conversationID: ChatConversation.ID
    var focusMessageID: ChatMessage.ID? = nil
    var pendingCallID: CallSessionRecord.ID? = nil

    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool
    @State private var copyFeedback: String?
    @State private var sendPulse = 0
    @State private var likePulse = 0
    @State private var replyTo: ChatMessage?
    @State private var selectedBuddy: DiscoverBuddyItem?
    @State private var selectedActivity: Activity?
    @State private var selectedPostID: CommunityPost.ID?
    @State private var showGroupManage = false
    @State private var showTransfer = false
    @State private var showReport = false
    @State private var confirmBlock = false
    @State private var confirmLeaveCircle = false
    @State private var showLocationPicker = false
    @State private var locationDraft = ""
    @State private var locationLatitude: Double?
    @State private var locationLongitude: Double?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var mentionDraft: String?
    @State private var pendingScrollMessageID: ChatMessage.ID?
    @State private var activeCallID: UUID?
    @State private var showCallHistory = false

    private var conversation: ChatConversation? {
        model.conversations.first { $0.id == conversationID }
    }

    private var messages: [ChatMessage] {
        guard let conversation else { return model.messages(for: conversationID) }
        return model.visibleMessages(
            for: conversationID,
            viewerName: app.user.name,
            ownerName: conversation.ownerName
        )
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if let conversation {
                chatBody(conversation)
            } else {
                ContentUnavailableView(
                    MessagesCopy.conversationMissing,
                    systemImage: "bubble.left.and.exclamationmark.bubble.right"
                )
            }
        }
        .platformSecondaryPage()
    }

    @ViewBuilder
    private func chatBody(_ conversation: ChatConversation) -> some View {
        let timeline = ChatTimelineItem.build(
            from: messages,
            isGroup: conversation.isGroup,
            isNotice: conversation.kind == .notice
        )

        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if messages.isEmpty {
                        PlatformChatEmptyThread(peerName: conversation.title)
                    } else {
                        ForEach(timeline) { item in
                            switch item {
                            case .day(let label, let id):
                                PlatformChatDaySeparator(label: label)
                                    .id(id)
                            case .tip(let message):
                                PlatformChatSystemTip(text: message.text)
                                    .id(message.id)
                            case .message(let message, let chrome):
                                messageRow(message, chrome: chrome, conversation: conversation)
                                    .id(message.id)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .platformMessageThreadScrollMargins()
            .onChange(of: messages.count) { _, _ in
                if pendingScrollMessageID == nil {
                    scrollToLatest(using: proxy)
                }
            }
            .onAppear {
                model.activeConversationID = conversationID
                model.markRead(conversationID)
                pendingScrollMessageID = focusMessageID
                if let focusMessageID,
                   messages.contains(where: { $0.id == focusMessageID }) {
                    DispatchQueue.main.async {
                        withAnimation(.easeOut(duration: 0.25)) {
                            proxy.scrollTo(focusMessageID, anchor: .center)
                        }
                        pendingScrollMessageID = nil
                    }
                } else {
                    scrollToLatest(using: proxy, animated: false)
                    pendingScrollMessageID = nil
                }
                if conversation.kind != .notice, messages.isEmpty {
                    isComposerFocused = true
                }
                if conversation.kind == .activity,
                   let activity = relatedActivity(for: conversation) {
                    app.handle(.activityUpdated(activity.id))
                }
                if activeCallID == nil, let pendingCallID {
                    activeCallID = pendingCallID
                    app.pendingCallID = nil
                }
                model.refreshTransferExpirations()
            }
            .onDisappear {
                if model.activeConversationID == conversationID {
                    model.activeConversationID = nil
                }
            }
            .onChange(of: messages.map(\.id)) { _, ids in
                if let replyTo, !ids.contains(replyTo.id) {
                    self.replyTo = nil
                }
            }
        }
        .background(PlatformSurface.canvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                chatToolbarTitle(conversation)
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
                ToolbarItem(placement: .topBarTrailing) {
                    conversationMoreMenu(conversation)
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    conversationMoreMenu(conversation)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if mentionDraft != nil {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                            ForEach(conversation.memberNames.filter { $0 != app.user.name }, id: \.self) { name in
                                Button("@\(name)") {
                                    draft += "@\(name) "
                                    mentionDraft = nil
                                    isComposerFocused = true
                                }
                                .font(.caption)
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .platformMessagePagePadding()
                        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
                    }
                }
                PlatformMessageComposerBar(
                    draft: $draft,
                    placeholder: conversation.kind == .notice
                        ? MessagesCopy.noticePlaceholder
                        : MessagesCopy.sendPlaceholder,
                    isEnabled: conversation.kind != .notice,
                    canSend: canSend,
                    isFocused: $isComposerFocused,
                    replyPreview: replyTo.map {
                        ($0.isMe ? "我" : $0.sender, $0.previewText)
                    },
                    onCancelReply: { replyTo = nil },
                    onVoice: {
                        _ = model.sendVoice(duration: Double.random(in: 2...12), to: conversation.id)
                        sendPulse += 1
                    },
                    attachMenu: Group {
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
                    },
                    onSend: { send(to: conversation.id) }
                )
            }
        }
        .onChange(of: photoPickerItem) { _, item in
            Task { await loadAndSendPhoto(item, conversationID: conversation.id) }
        }
        .sheet(isPresented: $showGroupManage) {
            GroupManageSheet(conversationID: conversationID) { activity in
                selectedActivity = activity
            }
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
            "退出组织？",
            isPresented: $confirmLeaveCircle
        ) {
            Button(MessagesCopy.leaveGroup, role: .destructive) {
                leaveCircleGroupIfPossible()
            }
            Button(MessagesCopy.cancel, role: .cancel) {}
        } message: {
            Text("退出后将离开组织群聊，成员设置会清除，可随时重新加入。")
        }
        .sensoryFeedback(.success, trigger: sendPulse)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: likePulse)
        .platformTransientFeedback($copyFeedback)
        .onChange(of: copyFeedback) { _, value in
            guard value != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                if copyFeedback == value { copyFeedback = nil }
            }
        }
        .onChange(of: model.conversations.map(\.id)) { _, ids in
            if !ids.contains(conversationID) { dismiss() }
        }
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
            NavigationStack { BuddyDetailRouteView(item: item) }
                .platformSheet(.browser)
        }
        .sheet(item: $selectedActivity) { activity in
            NavigationStack { ActivityDetailView(activity: activity) }
                .platformSheet(.browser)
        }
        .sheet(isPresented: Binding(
            get: { selectedPostID != nil },
            set: { if !$0 { selectedPostID = nil } }
        )) {
            if let selectedPostID {
                NavigationStack { CommunityPostDetailView(postID: selectedPostID) }
                    .platformSheet(.browser)
            }
        }
    }

    private func openLink(_ urlString: String) {
        if let postID = Self.communityPostID(from: urlString) {
            selectedPostID = postID
            return
        }
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private static func communityPostID(from urlString: String) -> UUID? {
        guard let url = URL(string: urlString),
              url.scheme == "zuobiaoxi",
              url.host == "community"
        else { return nil }
        let idString = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return UUID(uuidString: idString)
    }

    @ViewBuilder
    private func messageRow(
        _ message: ChatMessage,
        chrome: PlatformChatBubbleChrome,
        conversation: ChatConversation
    ) -> some View {
        PlatformChatBubble(
            text: message.text,
            sentAt: message.sentAt,
            sender: message.isMe ? app.user.name : message.sender,
            isMe: message.isMe,
            chrome: chrome,
            message: message,
            isLiked: message.isLiked,
            replyToSender: message.replyToSender,
            replyToText: message.replyToText,
            onTapAvatar: {
                if message.isMe { return }
                if conversation.kind == .direct {
                    selectedBuddy = buddies.item(for: conversation.title)
                } else {
                    selectedBuddy = buddies.item(for: message.sender)
                }
            },
            onDoubleTap: {
                guard conversation.kind != .notice else { return }
                model.toggleLike(messageID: message.id, in: conversationID)
                likePulse += 1
            },
            onOpenActivity: { id in
                selectedActivity = activities.activity(id: id)
            },
            onOpenLink: { urlString in
                openLink(urlString)
            }
        )
        .contextMenu {
            Button(MessagesCopy.copy, systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.previewText
                copyFeedback = MessagesCopy.copied
            }
            if conversation.kind != .notice {
                Button(MessagesCopy.reply, systemImage: "arrowshape.turn.up.left") {
                    replyTo = message
                    isComposerFocused = true
                }
                Button(
                    message.isLiked ? MessagesCopy.unlike : MessagesCopy.like,
                    systemImage: message.isLiked ? "heart.slash" : "heart"
                ) {
                    model.toggleLike(messageID: message.id, in: conversationID)
                    likePulse += 1
                }
                Menu(MessagesCopy.reactionMenu) {
                    ForEach(["❤️", "👍", "😂", "😮", "😢"], id: \.self) { emoji in
                        Button(emoji) {
                            model.setReaction(emoji, on: message.id, in: conversationID)
                        }
                    }
                    if message.reaction != nil {
                        Button(MessagesCopy.clearReaction, role: .destructive) {
                            model.setReaction(nil, on: message.id, in: conversationID)
                        }
                    }
                }
            }
            if message.isMe {
                Button(MessagesCopy.deleteMessage, systemImage: "trash", role: .destructive) {
                    if replyTo?.id == message.id { replyTo = nil }
                    model.deleteMessage(messageID: message.id, in: conversationID)
                }
            }
        }
    }

    @ViewBuilder
    private func chatToolbarTitle(_ conversation: ChatConversation) -> some View {
        let subtitle = conversation.navigationSubtitle(viewerName: app.user.name)
        let onTap: (() -> Void)? = {
            switch conversation.kind {
            case .direct:
                return { selectedBuddy = buddies.item(for: conversation.title) }
            case .activity, .circle, .group, .notice:
                return conversation.isGroup ? { showGroupManage = true } : nil
            }
        }()

        if let onTap {
            Button(action: onTap) {
                PlatformToolbarPrincipalCaption(
                    title: conversation.title,
                    subtitle: subtitle
                )
            }
            .platformToolbarPrincipalCapsuleStyle()
        } else {
            PlatformToolbarPrincipalCaption(
                title: conversation.title,
                subtitle: subtitle
            )
        }
    }

    @ViewBuilder
    private func conversationMoreMenu(_ conversation: ChatConversation) -> some View {
        Menu {
            Button(
                conversation.isPinned ? MessagesCopy.unpinConversation : MessagesCopy.pinConversation,
                systemImage: conversation.isPinned ? "pin.slash" : "pin"
            ) {
                model.togglePin(conversation.id)
            }
            Button(
                conversation.isMuted ? MessagesCopy.muteOff : MessagesCopy.muteOn,
                systemImage: conversation.isMuted ? "bell" : "bell.slash"
            ) {
                model.toggleMute(conversation.id)
            }
            if conversation.kind != .notice {
                Button(MessagesCopy.callHistoryTitle, systemImage: "clock.arrow.circlepath") {
                    showCallHistory = true
                }
            }
            if conversation.isGroup {
                Button(MessagesCopy.groupManage, systemImage: "person.3") {
                    showGroupManage = true
                }
            }
            if conversation.kind == .activity {
                Button(MessagesCopy.activityDetail, systemImage: "calendar") {
                    selectedActivity = relatedActivity(for: conversation)
                }
                .disabled(relatedActivity(for: conversation) == nil)
            }
            if conversation.kind == .direct {
                Button(MessagesCopy.viewProfile, systemImage: "person.crop.circle") {
                    selectedBuddy = buddies.item(for: conversation.title)
                }
                .disabled(buddies.item(for: conversation.title) == nil)
                Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble") {
                    showReport = true
                }
                Button(MessagesCopy.blockUser, systemImage: "hand.raised", role: .destructive) {
                    confirmBlock = true
                }
            } else if conversation.kind != .notice {
                Button(MessagesCopy.reportUser, systemImage: "exclamationmark.bubble") {
                    showReport = true
                }
            }
            if conversation.isActivityGroup {
                if conversation.isOwned(by: app.user.name) {
                    Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive) {
                        model.requestDelete(conversation)
                    }
                } else {
                    Button(MessagesCopy.leaveGroup, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        if let activityID = conversation.relatedActivityID {
                            app.cancelActivityRegistration(activityID)
                        } else {
                            model.requestDelete(conversation)
                        }
                    }
                }
            } else if conversation.isPeerGroup {
                if conversation.isOwned(by: app.user.name) {
                    Button(MessagesCopy.dissolveGroup, systemImage: "trash", role: .destructive) {
                        model.requestDelete(conversation)
                    }
                } else {
                    Button(MessagesCopy.leaveGroup, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        model.requestDelete(conversation)
                    }
                }
            } else if conversation.isCircleGroup {
                Button(MessagesCopy.leaveGroup, systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    confirmLeaveCircle = true
                }
            } else {
                Button(MessagesCopy.deleteConversation, systemImage: "trash", role: .destructive) {
                    model.requestDelete(conversation)
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel(MessagesCopy.more)
    }

    private func send(to id: ChatConversation.ID) {
        guard model.send(text: draft, to: id, replyingTo: replyTo) != nil else { return }
        draft = ""
        replyTo = nil
        sendPulse += 1
    }

    private func leaveCircleGroupIfPossible() {
        guard let conversation else {
            return
        }
        if let circleID = conversation.relatedCircleID,
           let circle = SampleData.interestCircles.first(where: { $0.id == circleID }) {
            model.leaveCircleChat(circleID: circleID, leaverName: app.user.name)
            buddies.leaveCircle(circle)
        } else {
            model.requestDelete(conversation)
        }
    }

    private func loadAndSendPhoto(_ item: PhotosPickerItem?, conversationID: ChatConversation.ID) async {
        guard let item else { return }
        defer { photoPickerItem = nil }
        guard let data = try? await item.loadTransferable(type: Data.self),
              UIImage(data: data) != nil,
              let name = CommunityPhotoStore.saveJPEG(data)
        else { return }
        _ = model.sendImage(localName: name, to: conversationID)
        sendPulse += 1
    }

    private func relatedActivity(for conversation: ChatConversation) -> Activity? {
        if let id = conversation.relatedActivityID {
            return activities.activity(id: id)
        }
        return activities.activity(matchingTitle: conversation.title)
    }

    private func scrollToLatest(using proxy: ScrollViewProxy, animated: Bool = true) {
        guard let id = messages.last?.id else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(id, anchor: .bottom)
        }
    }
}

#Preview("活动群聊天") {
    NavigationStack {
        ConversationDetailView(conversationID: SampleData.conversations[0].id)
    }
    .environment(AppModel())
    .environment(MessagesModel())
    .environment(BuddiesModel())
    .environment(ActivitiesModel(currentUserName: SampleData.currentUser.name))
}
