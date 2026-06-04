// Module: SparkMessages — Messages tab root presentation.

import SparkDesignSystem
import SwiftUI

public struct MessagesRootView: View {
    @Binding private var pendingConversationThreadID: String?
    public var viewModel: MessagesViewModel

    @State private var navigationPath = NavigationPath()

    public init(
        viewModel: MessagesViewModel,
        pendingConversationThreadID: Binding<String?> = .constant(nil)
    ) {
        self.viewModel = viewModel
        _pendingConversationThreadID = pendingConversationThreadID
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
                ConversationDetailView(viewModel: viewModel.conversationViewModel(for: thread))
            }
            .task {
                if viewModel.loadState == .idle {
                    await viewModel.load()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        MessagesUnreadToolbarBadge(count: viewModel.unreadMessageCount)

                        Button(
                            String(localized: "messages.markRead", defaultValue: "全部已读", comment: "Messages action")
                        ) {
                            Task { await viewModel.markMessagesRead() }
                        }
                        .disabled(viewModel.unreadMessageCount == 0)
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
    }

    @ViewBuilder
    private var inboxContent: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty:
            ContentUnavailableView(
                String(localized: "messages.empty.title", defaultValue: "暂无消息", comment: "Empty inbox"),
                systemImage: "tray",
                description: Text(
                    String(localized: "messages.empty.subtitle", defaultValue: "开始和好友聊天吧", comment: "Empty inbox hint")
                )
            )
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "messages.error.title", defaultValue: "加载失败", comment: "Inbox error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            List(viewModel.threads) { thread in
                NavigationLink(value: thread) {
                    SparkMessageRow(
                        name: thread.peerDisplayName,
                        preview: thread.lastMessagePreview,
                        isUnread: thread.unreadCount > 0
                    )
                }
            }
            .sparkScreenListStyle()
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

// MARK: - Row

private struct SparkMessageRow: View {
    let name: String
    let preview: String
    let isUnread: Bool

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 44))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                    Spacer()
                    if isUnread {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .accessibilityHidden(true)
                    }
                }
                Text(preview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(name)
        .accessibilityValue(isUnread ? unreadAccessibilityValue : preview)
    }

    private var unreadAccessibilityValue: String {
        let format = String(
            localized: "messages.row.unread.format",
            defaultValue: "未读，%@",
            comment: "Unread row; %@ is message preview"
        )
        return String(format: format, locale: .current, preview)
    }
}

#Preview {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 3)))
}

#Preview("Messages — no unread") {
    MessagesRootView(viewModel: MessagesViewModel(repository: MockMessagesRepository(unreadCount: 0)))
}
