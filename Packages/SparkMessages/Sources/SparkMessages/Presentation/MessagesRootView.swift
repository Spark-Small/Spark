// Module: SparkMessages — DM and activity group chat inbox.

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct MessagesRootView: View {
    static let logger = SparkLog.logger(category: "Messages.RootView")

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    @Binding var pendingConversationThreadID: String?
    var viewModel: MessagesViewModel
    var onOpenActivity: ((String) -> Void)?
    var onProposeMeetup: ((String) -> Void)?
    var onOpenActivityTab: (() -> Void)?
    var onScannedPayload: ((String) -> Void)?

    @State var navigationPath = NavigationPath()
    @State var selectedThreadID: MessageThreadID?
    @State var matchOpenErrorMessage: String?
    @State var showQRScanner = false
    @State var showNewChatPicker = false
    @State var selectedInboxSegment: MessagesInboxSegment = .dm
    @State var hasAppliedInitialInboxSegment = false
    @State var inboxSearchText = ""

    @Environment(PeerDisplayNameStore.self) var peerDisplayNameStore

    var usesSplitInbox: Bool {
        horizontalSizeClass == .regular
    }

    public init(
        viewModel: MessagesViewModel,
        pendingConversationThreadID: Binding<String?> = .constant(nil),
        onOpenActivity: ((String) -> Void)? = nil,
        onProposeMeetup: ((String) -> Void)? = nil,
        onOpenActivityTab: (() -> Void)? = nil,
        onScannedPayload: ((String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        _pendingConversationThreadID = pendingConversationThreadID
        self.onOpenActivity = onOpenActivity
        self.onProposeMeetup = onProposeMeetup
        self.onOpenActivityTab = onOpenActivityTab
        self.onScannedPayload = onScannedPayload
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
                .navigationSplitViewColumnWidth(
                    min: 280,
                    ideal: SparkLayoutMetrics.navigationSplitSidebarIdealWidth,
                    max: 400
                )
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
            navigationTitle: "",
            titleDisplayMode: .inline,
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
            ToolbarItem(placement: .principal) {
                if showsInboxSegmentPicker {
                    inboxSegmentToolbarPicker
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                inboxActionsMenu
            }
        }
        .sparkPhoneStyleNavigationBar()
        .onChange(of: peerDisplayNameStore.changeToken) { _, _ in
            viewModel.refreshDisplayNames()
        }
        .onChange(of: viewModel.loadState) { _, _ in
            applyInitialInboxSegmentIfNeeded()
        }
        .sheet(isPresented: $showQRScanner) {
            MessagesQRScanSheet { payload in
                onScannedPayload?(payload)
            }
        }
        .sheet(isPresented: $showNewChatPicker) {
            newChatPickerSheet
        }
    }

    @ViewBuilder
    private var inboxContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkLoadingAccessibilityLabel(
                    String(
                        localized: "messages.loading.a11y",
                        defaultValue: "正在加载消息",
                        comment: "Inbox loading"
                    )
                )
        case .empty:
            loadedInboxSegmentContent
                .onAppear {
                    selectedInboxSegment = .dm
                }
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "messages.error.title", defaultValue: "加载失败", comment: "Inbox error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            loadedInboxSegmentContent
                .accessibilityLabel(inboxLoadedAccessibilityLabel)
                .onAppear {
                    applyInitialInboxSegmentIfNeeded()
                }
        }
    }

    private var showsInboxSegmentPicker: Bool {
        switch viewModel.loadState {
        case .failure:
            false
        case .idle, .loading, .empty, .loaded:
            true
        }
    }

    private var inboxLoadedAccessibilityLabel: String {
        let unread = viewModel.totalUnreadCount
        if unread > 0 {
            let format = String(
                localized: "messages.inbox.loaded.unread.format",
                defaultValue: "消息列表，%1$d 条未读",
                comment: "Inbox loaded; unread count"
            )
            return String(format: format, locale: .current, unread)
        }
        return String(
            localized: "messages.inbox.loaded.a11y",
            defaultValue: "消息列表",
            comment: "Inbox loaded"
        )
    }
}

#Preview {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
}

#Preview("Messages — no unread") {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 0)))
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
}

#Preview("Messages — failure") {
    MessagesRootView(viewModel: MessagesViewModel(repository: PreviewFailingInboxRepository()))
        .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
}

#Preview("Messages — dark") {
    SparkPreviewSupport.darkMode {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
            .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
    }
}

#Preview("Messages — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
            .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
    }
}

#Preview("Messages — iPad split") {
    SparkPreviewSupport.iPadRegular {
        MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
            .environment(PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore()))
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
    func sendMessage(threadID: MessageThreadID, body: String, kind: ChatMessageKind = .text) async throws -> ChatMessage { throw Failure() }
    func markAllRead() async throws { throw Failure() }
    func markThreadRead(threadID: MessageThreadID) async throws { throw Failure() }
    func hideThread(threadID: MessageThreadID) async throws { throw Failure() }
    func deleteThread(threadID: MessageThreadID) async throws { throw Failure() }
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws { throw Failure() }
    func dismissInboxActionItem(id: String) async throws { throw Failure() }
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws {
        throw Failure()
    }
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        throw Failure()
    }
}
