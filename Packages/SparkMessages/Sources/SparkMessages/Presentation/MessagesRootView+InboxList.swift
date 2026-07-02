// Module: SparkMessages — Unified inbox list and navigation.

import SparkDesignSystem
import SwiftUI

extension MessagesRootView {
    @ViewBuilder
    func inboxConversationList<Rows: View>(
        segment: MessagesInboxSegment,
        @ViewBuilder rows: () -> Rows
    ) -> some View {
        List {
            MessagesInboxSearchBar(text: $inboxSearchText, segment: segment)
                .sparkInboxSearchListRow()
            rows()
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.load()
        }
    }

    var inboxActionsMenu: some View {
        Menu {
            Button {
                showNewChatPicker = true
            } label: {
                Label(
                    String(
                        localized: "messages.action.startChat",
                        defaultValue: "发起聊天",
                        comment: "Start new direct message"
                    ),
                    systemImage: "bubble.left.and.bubble.right"
                )
            }
            Button {
                showQRScanner = true
            } label: {
                Label(
                    String(localized: "messages.action.scan", defaultValue: "扫一扫", comment: "Scan QR code"),
                    systemImage: "qrcode.viewfinder"
                )
            }
            if viewModel.totalUnreadCount > 0 {
                Button {
                    Task { await viewModel.markMessagesRead() }
                } label: {
                    Label(
                        String(localized: "messages.markRead", defaultValue: "全部已读", comment: "Messages action"),
                        systemImage: "envelope.open"
                    )
                }
            }
        } label: {
            Image(systemName: "plus.circle")
        }
        .accessibilityLabel(
            String(localized: "messages.actions.menu.a11y", defaultValue: "消息操作", comment: "Messages actions menu")
        )
    }

    @ViewBuilder
    func inboxConversationRow(_ conversation: ConversationPreview) -> some View {
        if conversation.kind == .dm, let match = viewModel.matchPreview(for: conversation) {
            matchConversationRow(conversation: conversation, match: match)
        } else {
            conversationRow(conversation)
        }
    }

    @ViewBuilder
    func matchConversationRow(conversation: ConversationPreview, match: MatchPreview) -> some View {
        Button {
            Task { await openMatchConversation(match) }
        } label: {
            ConversationRow(conversation: conversation, isNewMatch: true)
        }
        .buttonStyle(.sparkPressable)
        .sparkFlatTabListRow()
        .messagesConversationSwipeActions(
            conversation: conversation,
            onMarkRead: { Task { await viewModel.markConversationRead(conversation) } },
            onHide: { Task { await hideConversation(conversation) } },
            onDelete: { Task { await deleteConversation(conversation) } }
        )
        .accessibilityHint(
            String(
                localized: "messages.match.open.hint",
                defaultValue: "打开与新配对的对话",
                comment: "Open new match conversation hint"
            )
        )
    }

    @ViewBuilder
    func conversationRow(_ conversation: ConversationPreview) -> some View {
        NavigationLink(value: conversation.asMessageThread()) {
            ConversationRow(conversation: conversation)
        }
        .sparkFlatTabListRow()
        .messagesConversationSwipeActions(
            conversation: conversation,
            onMarkRead: { Task { await viewModel.markConversationRead(conversation) } },
            onHide: { Task { await hideConversation(conversation) } },
            onDelete: { Task { await deleteConversation(conversation) } }
        )
    }

    @ViewBuilder
    func archivedGroupChatRow(_ conversation: ConversationPreview) -> some View {
        conversationRow(conversation)
    }

    @MainActor
    func hideConversation(_ conversation: ConversationPreview) async {
        await viewModel.hideConversation(conversation)
    }

    @MainActor
    func deleteConversation(_ conversation: ConversationPreview) async {
        await viewModel.deleteConversation(conversation)
    }

    func conversationDetail(for thread: MessageThread) -> some View {
        ConversationDetailView(
            viewModel: viewModel.conversationViewModel(for: thread),
            onOpenActivity: onOpenActivity,
            onProposeMeetup: onProposeMeetup
        )
        .task(id: thread.threadID) {
            guard let conversation = viewModel.conversation(for: thread.threadID),
                  conversation.hasUnread else { return }
            await viewModel.markConversationRead(conversation)
        }
    }

    @MainActor
    func openMatchConversation(_ match: MatchPreview) async {
        do {
            let threadID = try await viewModel.ensureDirectMessageThread(for: match)
            viewModel.graduateMatch(match, to: threadID)
            await viewModel.load()
            if let thread = viewModel.thread(for: threadID) {
                openThread(thread)
            }
        } catch {
            Self.logger.error(
                "ensureDirectMessageThread failed: \(error.localizedDescription, privacy: .public)"
            )
            matchOpenErrorMessage = (error as? MessagesError)?.errorDescription ?? error.localizedDescription
        }
    }

    @MainActor
    func openPendingConversation(threadID: String) async {
        if viewModel.loadState != .loaded {
            await viewModel.load()
        }
        if let thread = viewModel.thread(for: MessageThreadID(threadID)) {
            openThread(thread)
            pendingConversationThreadID = nil
            return
        }
        await viewModel.load()
        guard let thread = viewModel.thread(for: MessageThreadID(threadID)) else {
            pendingConversationThreadID = nil
            return
        }
        openThread(thread)
        pendingConversationThreadID = nil
    }

    @MainActor
    func openThread(_ thread: MessageThread) {
        if let conversation = viewModel.conversation(for: thread.threadID) {
            selectedInboxSegment = conversation.kind == .dm ? .dm : .groupChats
        }
        navigationPath.append(thread)
    }
}
