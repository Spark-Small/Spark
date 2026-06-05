// Module: SparkMessages — Three-section unified inbox.

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct MessagesRootView: View {
    private static let logger = SparkLog.logger(category: "Messages.RootView")

    @Binding private var pendingConversationThreadID: String?
    public var viewModel: MessagesViewModel
    public var onOpenActivity: ((String) -> Void)?
    public var onOpenLikes: (() -> Void)?

    @State private var navigationPath = NavigationPath()
    @State private var matchOpenErrorMessage: String?

    public init(
        viewModel: MessagesViewModel,
        pendingConversationThreadID: Binding<String?> = .constant(nil),
        onOpenActivity: ((String) -> Void)? = nil,
        onOpenLikes: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        _pendingConversationThreadID = pendingConversationThreadID
        self.onOpenActivity = onOpenActivity
        self.onOpenLikes = onOpenLikes
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack(path: $navigationPath) {
            SparkScreenContainer(
                navigationTitle: String(localized: "screen.messages", defaultValue: "消息", comment: "Messages screen"),
                embedding: .none
            ) {
                inboxContent
            }
            .navigationDestination(for: MessageThread.self) { thread in
                ConversationDetailView(
                    viewModel: viewModel.conversationViewModel(for: thread),
                    onOpenActivity: onOpenActivity
                )
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        MessagesUnreadToolbarBadge(count: viewModel.totalUnreadCount)

                        Button(
                            String(localized: "messages.markRead", defaultValue: "全部已读", comment: "Messages action")
                        ) {
                            Task { await viewModel.markMessagesRead() }
                        }
                        .disabled(viewModel.dmUnreadCount + viewModel.groupUnreadCount == 0)
                    }
                }
            }
            .toolbarBackground(.automatic, for: .navigationBar)
        }
        .onChange(of: pendingConversationThreadID) { _, threadID in
            guard let threadID else { return }
            Task { await openPendingConversation(threadID: threadID) }
        }
        .onAppear {
            if let threadID = pendingConversationThreadID {
                Task { await openPendingConversation(threadID: threadID) }
            }
        }
        .alert(
            String(localized: "messages.match.error.title", defaultValue: "无法开始聊天", comment: "Match open error"),
            isPresented: Binding(
                get: { matchOpenErrorMessage != nil },
                set: { if !$0 { matchOpenErrorMessage = nil } }
            )
        ) {
            Button(String(localized: "common.ok", defaultValue: "好", comment: "OK"), role: .cancel) {
                matchOpenErrorMessage = nil
            }
        } message: {
            Text(matchOpenErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var inboxContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            emptyInboxView
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "messages.error.title", defaultValue: "加载失败", comment: "Inbox error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            inboxList
        }
    }

    private var emptyInboxView: some View {
        ContentUnavailableView {
            Label(
                String(localized: "messages.empty.title", defaultValue: "暂无消息", comment: "Empty inbox"),
                systemImage: "tray"
            )
        } description: {
            Text(
                String(localized: "messages.empty.subtitle", defaultValue: "开始和好友聊天吧", comment: "Empty inbox hint")
            )
        } actions: {
            if let onOpenLikes {
                Button(
                    String(localized: "messages.empty.cta.likes", defaultValue: "去看看喜欢", comment: "Open likes"),
                    action: onOpenLikes
                )
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var inboxList: some View {
        List {
            Section {
                ActionItemsSection(
                    items: viewModel.actionItems,
                    onInviteAccept: { invite in
                        Task { await viewModel.handleInviteResponse(invite: invite, accept: true) }
                    },
                    onInviteDecline: { invite in
                        Task { await viewModel.handleInviteResponse(invite: invite, accept: false) }
                    },
                    onOpenActivity: { activityID in
                        onOpenActivity?(activityID)
                    },
                    onDismiss: { item in
                        Task { await viewModel.dismissActionItem(id: item.id) }
                    }
                )
            }

            if !viewModel.unmessagedMatches.isEmpty || !viewModel.dmConversations.isEmpty {
                Section {
                    if !viewModel.unmessagedMatches.isEmpty {
                        NewMatchesCarousel(matches: viewModel.unmessagedMatches) { match in
                            Task { await openMatchConversation(match) }
                        }
                    }
                    ForEach(viewModel.dmConversations) { conversation in
                        NavigationLink(value: conversation.asMessageThread()) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                } header: {
                    InboxSectionHeader(
                        title: String(localized: "messages.section.dm", defaultValue: "配对消息", comment: "DM section"),
                        systemImage: "heart.fill",
                        unreadCount: viewModel.dmUnreadCount
                    )
                }
            }

            if !viewModel.activeGroupChats.isEmpty || !viewModel.archivedGroupChats.isEmpty {
                Section {
                    ForEach(viewModel.activeGroupChats) { conversation in
                        NavigationLink(value: conversation.asMessageThread()) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    if !viewModel.archivedGroupChats.isEmpty {
                        ArchivedChatsDisclosure(chats: viewModel.archivedGroupChats)
                    }
                } header: {
                    InboxSectionHeader(
                        title: String(localized: "messages.section.group", defaultValue: "活动群聊", comment: "Group section"),
                        systemImage: "figure.hiking",
                        unreadCount: viewModel.groupUnreadCount
                    )
                }
            }
        }
        .sparkScreenListStyle()
    }

    @MainActor
    private func openMatchConversation(_ match: MatchPreview) async {
        do {
            let threadID = try await viewModel.ensureDirectMessageThread(for: match)
            await viewModel.load()
            if let thread = viewModel.thread(for: threadID) {
                navigationPath.append(thread)
            }
        } catch {
            Self.logger.error(
                "ensureDirectMessageThread failed: \(error.localizedDescription, privacy: .public)"
            )
            matchOpenErrorMessage = (error as? MessagesError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    private func openPendingConversation(threadID: String) async {
        if viewModel.loadState != .loaded {
            await viewModel.load()
        }
        if let thread = viewModel.thread(for: MessageThreadID(threadID)) {
            navigationPath.append(thread)
            pendingConversationThreadID = nil
            return
        }
        await viewModel.load()
        guard let thread = viewModel.thread(for: MessageThreadID(threadID)) else {
            pendingConversationThreadID = nil
            return
        }
        navigationPath.append(thread)
        pendingConversationThreadID = nil
    }
}

#Preview {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
}

#Preview("Messages — no unread") {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 0)))
}

#Preview("Messages — failure") {
    MessagesRootView(viewModel: MessagesViewModel(repository: PreviewFailingInboxRepository()))
}

private struct PreviewFailingInboxRepository: MessagesRepository, Sendable {
    struct Failure: LocalizedError {
        var errorDescription: String? { "Inbox unavailable" }
    }

    func fetchUnreadCount() async throws -> Int { throw Failure() }
    func fetchThreads() async throws -> [MessageThread] { throw Failure() }
    func fetchInbox() async throws -> MessagesInbox { throw Failure() }
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] { throw Failure() }
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext { throw Failure() }
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage { throw Failure() }
    func markAllRead() async throws { throw Failure() }
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws { throw Failure() }
    func dismissInboxActionItem(id: String) async throws { throw Failure() }
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {
        throw Failure()
    }
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        throw Failure()
    }
}
