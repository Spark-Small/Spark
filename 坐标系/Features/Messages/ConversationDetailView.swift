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
    @State var peerProfile: ConversationPeerProfileRoute?
    @State var selectedActivity: Activity?
    @State var selectedPostID: CommunityPost.ID?
    @State var showGroupManage = false
    @State var showReport = false
    @State var confirmLeaveCircle = false
    @State var confirmClearHistory = false
    @State var confirmLeavePeerGroup = false
    @State var confirmDissolveGroup = false
    @State var editingMessage: ChatMessage?
    @State var editDraft = ""
    @State var forwardingMessage: ChatMessage?
    @State var confirmLocalVoice = false
    @State var showLocationPicker = false
    @State var locationDraft = ""
    @State var locationLatitude: Double?
    @State var locationLongitude: Double?
    @State var photoPickerItem: PhotosPickerItem?
    @State var mentionDraft: String?
    @State var pendingScrollMessageID: ChatMessage.ID?
    @State var activeCallID: UUID?

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

        withConversationPresentations(
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
                        let name = conversation.kind == .direct
                            ? conversation.title
                            : message.sender
                        peerProfile = peerProfileRoute(for: name)
                    },
                    onToggleLike: {
                        model.toggleLike(messageID: message.id, in: conversationID)
                        likePulse += 1
                    },
                    onReply: {
                        replyTo = message
                        isComposerFocused = true
                    },
                    onEdit: {
                        editingMessage = message
                        editDraft = message.text
                    },
                    onUnsend: {
                        if model.unsendMessage(messageID: message.id, in: conversationID) {
                            if replyTo?.id == message.id { replyTo = nil }
                        } else {
                            copyFeedback = MessagesCopy.unsendUnavailable
                        }
                    },
                    onForward: { forwardingMessage = message },
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
                ToolbarItem(placement: .topBarTrailing) {
                    moreMenu(for: conversation)
                }
            }
            // 官方范式：Scroll + `safeAreaInset(edge: .bottom, spacing: 0)` + `.background(.bar)`
            // （控件与键盘间距靠 Composer 内 `composerBarVerticalPadding`，非 inset spacing）
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
                    memberNamesExcludingSelf: conversation.memberNames.filter { $0 != app.user.name },
                    onCancelReply: { replyTo = nil },
                    onSend: { send(to: conversation.id) },
                    onVoice: conversation.kind == .notice ? nil : { confirmLocalVoice = true }
                ) {
                    attachMenu(for: conversation)
                }
                .background(.bar)
            },
            conversation: conversation
        )
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
