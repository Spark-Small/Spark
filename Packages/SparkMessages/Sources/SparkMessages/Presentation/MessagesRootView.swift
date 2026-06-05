// Module: SparkMessages — Three-section unified inbox.

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct MessagesRootView: View {
    static let logger = SparkLog.logger(category: "Messages.RootView")

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var pendingConversationThreadID: String?
    var viewModel: MessagesViewModel
    var onOpenActivity: ((String) -> Void)?
    var onOpenLikes: (() -> Void)?

    @State var navigationPath = NavigationPath()
    @State var selectedThreadID: MessageThreadID?
    @State var matchOpenErrorMessage: String?

    var usesSplitInbox: Bool {
        horizontalSizeClass == .regular
    }

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

        Group {
            if usesSplitInbox {
                splitInbox
            } else {
                compactInbox
            }
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

    private var compactInbox: some View {
        NavigationStack(path: $navigationPath) {
            inboxShell
                .navigationDestination(for: MessageThread.self) { thread in
                    conversationDetail(for: thread)
                }
        }
    }

    private var splitInbox: some View {
        NavigationSplitView {
            inboxShell
        } detail: {
            if let threadID = selectedThreadID,
               let thread = viewModel.thread(for: threadID) {
                conversationDetail(for: thread)
            } else {
                ContentUnavailableView {
                    Label(
                        String(
                            localized: "messages.split.empty.title",
                            defaultValue: "选择对话",
                            comment: "Split inbox placeholder"
                        ),
                        systemImage: "bubble.left.and.bubble.right"
                    )
                } description: {
                    Text(
                        String(
                            localized: "messages.split.empty.subtitle",
                            defaultValue: "从左侧列表打开一条消息",
                            comment: "Split inbox hint"
                        )
                    )
                }
            }
        }
    }

    private var inboxShell: some View {
        SparkScreenContainer(
            navigationTitle: String(localized: "screen.messages", defaultValue: "消息", comment: "Messages screen"),
            embedding: .none
        ) {
            inboxContent
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

#Preview("Messages — dark") {
    SparkPreviewSupport.darkMode {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
}

#Preview("Messages — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
}

#Preview("Messages — iPad split") {
    SparkPreviewSupport.iPadRegular {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
}

#Preview("Messages — dark") {
    SparkPreviewSupport.darkMode {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
}

#Preview("Messages — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
}

#Preview("Messages — iPad split") {
    SparkPreviewSupport.iPadRegular {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
    }
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
    func markThreadRead(threadID: MessageThreadID) async throws { throw Failure() }
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws { throw Failure() }
    func dismissInboxActionItem(id: String) async throws { throw Failure() }
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {
        throw Failure()
    }
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        throw Failure()
    }
}
