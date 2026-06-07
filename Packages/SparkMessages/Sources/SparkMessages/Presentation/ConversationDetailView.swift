// Module: SparkMessages — Thread detail with rich message kinds.

import PhotosUI
import SparkDesignSystem
import SwiftUI

public struct ConversationDetailView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable public var viewModel: ConversationViewModel
    public var onOpenActivity: ((String) -> Void)?
    public var onProposeMeetup: ((String) -> Void)?

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showPeerProfile = false

    public init(
        viewModel: ConversationViewModel,
        onOpenActivity: ((String) -> Void)? = nil,
        onProposeMeetup: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onOpenActivity = onOpenActivity
        self.onProposeMeetup = onProposeMeetup
    }

    public var body: some View {
        Group {
            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sparkLoadingAccessibilityLabel(
                        String(
                            localized: "messages.conversation.loading.a11y",
                            defaultValue: "正在加载对话",
                            comment: "Conversation loading"
                        )
                    )
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "messages.conversation.error.title",
                        defaultValue: "无法加载",
                        comment: "Conversation error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.load() }
                }
            case .loaded:
                messageList
            }
        }
        .background(.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                conversationNavHeader
            }
        }
        .navigationDestination(isPresented: $showPeerProfile) {
            if let peerUserID = viewModel.peerUserID {
                ConversationPeerProfileView(
                    peerUserID: peerUserID,
                    peerDisplayName: viewModel.dmPartner?.displayName ?? viewModel.thread.peerDisplayName,
                    context: viewModel.context,
                    onOpenActivity: onOpenActivity,
                    onProposeMeetup: {
                        let peerName = viewModel.dmPartner?.displayName ?? viewModel.thread.peerDisplayName
                        onProposeMeetup?(peerName)
                    }
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                if let sendError = viewModel.sendErrorMessage {
                    Text(sendError)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
                        .accessibilityLabel(sendError)
                }
                MessagesComposerBar(
                    draft: $viewModel.draftText,
                    selectedPhotoItem: $selectedPhotoItem,
                    isSending: viewModel.isSending,
                    sendSuccessToken: viewModel.sendSuccessToken,
                    onSend: {
                        Task { await viewModel.sendTapped() }
                    }
                )
            }
        }
        .onChange(of: selectedPhotoItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await viewModel.sendImage(data)
                }
                selectedPhotoItem = nil
            }
        }
        .task {
            if viewModel.loadState == .idle {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    private var conversationNavHeader: some View {
        Button {
            if viewModel.isDirectMessage {
                showPeerProfile = true
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isDirectMessage {
                    ConversationHeaderAvatar(
                        imageURL: viewModel.dmPartner?.avatarURL,
                        displayName: viewModel.resolvedDisplayName,
                        placeholderSystemImage: "person.circle.fill"
                    )
                } else {
                    ConversationHeaderAvatar(
                        imageURL: viewModel.groupActivity?.coverURL,
                        displayName: viewModel.resolvedDisplayName,
                        placeholderSystemImage: "person.3.fill"
                    )
                }
                Text(viewModel.resolvedDisplayName)
                    .font(.headline)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isDirectMessage)
        .accessibilityLabel(viewModel.resolvedDisplayName)
        .accessibilityHint(
            viewModel.isDirectMessage
                ? String(
                    localized: "messages.peer.profile.a11y",
                    defaultValue: "查看资料",
                    comment: "Peer profile"
                )
                : ""
        )
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    sharedActivityContextCards
                    ForEach(viewModel.messages) { message in
                        ConversationMessageView(message: message, onOpenActivity: onOpenActivity)
                            .id(message.id)
                    }
                }
                .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.sectionVerticalPadding)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                guard let last = viewModel.messages.last?.id else { return }
                if reduceMotion {
                    proxy.scrollTo(last, anchor: .bottom)
                } else {
                    withAnimation {
                        proxy.scrollTo(last, anchor: .bottom)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sharedActivityContextCards: some View {
        if viewModel.isDirectMessage, let activities = viewModel.context?.sharedActivities, !activities.isEmpty {
            ForEach(activities) { activity in
                SharedActivityContextCard(
                    activity: activity,
                    contextLabel: String(
                        localized: "messages.dm.sharedActivity",
                        defaultValue: "共同活动",
                        comment: "Shared activity"
                    ),
                    showsCountdown: true,
                    onOpen: onOpenActivity
                )
            }
        } else if viewModel.isGroupChat, let activity = viewModel.groupBannerActivity {
            SharedActivityContextCard(
                activity: activity,
                contextLabel: String(
                    localized: "messages.group.activityContext",
                    defaultValue: "活动群聊",
                    comment: "Group activity context"
                ),
                onOpen: onOpenActivity
            )
        }
    }
}

#Preview {
    NavigationStack {
        ConversationDetailView(
            viewModel: MessagesCoordinator(repository: MockMessagesRepository(unreadCount: 2))
                .makeConversationViewModel(
                    thread: MessageThread(
                        threadID: MessageThreadID("th_activity_act_1"),
                        peerDisplayName: "周末徒步 · 群",
                        lastMessagePreview: "周六 9:30 北门集合",
                        lastActivityAt: .now,
                        unreadCount: 1
                    ),
                    peerDisplayNameStore: PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
                )
        )
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
    }
}

#Preview("Conversation — load failure") {
    NavigationStack {
        ConversationDetailView(
            viewModel: ConversationViewModel(
                repository: PreviewFailingConversationRepository(),
                thread: MessageThread(
                    threadID: MessageThreadID("th_dm_u_like_1"),
                    peerDisplayName: "Preview",
                    lastMessagePreview: "",
                    lastActivityAt: .now,
                    unreadCount: 0
                )
            )
        )
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
    }
}

#Preview("Conversation — dark") {
    SparkPreviewSupport.darkMode {
        NavigationStack {
            ConversationDetailView(
                viewModel: ConversationViewModel(
                    repository: MockMessagesRepository(unreadCount: 2),
                    thread: MessageThread(
                        threadID: MessageThreadID("th_dm_u_like_1"),
                        peerDisplayName: "小雨",
                        lastMessagePreview: "你好",
                        lastActivityAt: .now,
                        unreadCount: 0
                    )
                )
            )
            .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
        }
    }
}

#Preview("Conversation — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        NavigationStack {
            ConversationDetailView(
                viewModel: ConversationViewModel(
                    repository: MockMessagesRepository(unreadCount: 2),
                    thread: MessageThread(
                        threadID: MessageThreadID("th_dm_u_like_1"),
                        peerDisplayName: "小雨",
                        lastMessagePreview: "你好",
                        lastActivityAt: .now,
                        unreadCount: 0
                    )
                )
            )
            .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
        }
    }
}

private struct PreviewFailingConversationRepository: MessagesRepository, Sendable {
    struct Failure: LocalizedError {
        var errorDescription: String? { "Preview failure" }
    }

    func fetchUnreadCount() async throws -> Int { 0 }
    func fetchThreads() async throws -> [MessageThread] { [] }
    func fetchInbox() async throws -> MessagesInbox { MessagesInbox() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { throw Failure() }
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext { throw Failure() }
    func sendMessage(threadID: MessageThreadID, body: String, kind: ChatMessageKind = .text) async throws -> ChatMessage { throw Failure() }
    func markAllRead() async throws {}
    func markThreadRead(threadID: MessageThreadID) async throws {}
    func hideThread(threadID: MessageThreadID) async throws {}
    func deleteThread(threadID: MessageThreadID) async throws {}
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {}
    func dismissInboxActionItem(id: String) async throws {}
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {}
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        MessageThreadID("th_dm_preview")
    }
}
