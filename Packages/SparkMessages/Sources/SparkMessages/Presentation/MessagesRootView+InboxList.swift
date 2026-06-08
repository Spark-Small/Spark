// Module: SparkMessages — Inbox list sections and row chrome.

import SwiftUI

extension MessagesRootView {
    @ViewBuilder
    var inboxList: some View {
        if usesSplitInbox {
            List(selection: $selectedThreadID) {
                inboxListSections
            }
            .sparkScreenListStyle()
            .refreshable {
                await viewModel.load()
            }
        } else {
            List {
                inboxListSections
            }
            .sparkScreenListStyle()
            .refreshable {
                await viewModel.load()
            }
        }
    }

    @ViewBuilder
    var inboxListSections: some View {
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
                    conversationRow(conversation)
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
                    conversationRow(conversation)
                }
                if !viewModel.archivedGroupChats.isEmpty {
                    ArchivedChatsDisclosure(chats: viewModel.archivedGroupChats) { conversation in
                        conversationRow(conversation)
                    }
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

    @ViewBuilder
    func conversationRow(_ conversation: ConversationPreview) -> some View {
        let row = ConversationRow(conversation: conversation)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    Task { await viewModel.deleteConversation(conversation) }
                } label: {
                    Label(
                        String(localized: "messages.row.delete", defaultValue: "删除", comment: "Delete conversation swipe"),
                        systemImage: "trash"
                    )
                }
                Button {
                    Task { await viewModel.hideConversation(conversation) }
                } label: {
                    Label(
                        String(localized: "messages.row.hide", defaultValue: "隐藏", comment: "Hide conversation swipe"),
                        systemImage: "eye.slash"
                    )
                }
                .tint(.indigo)
                if conversation.hasUnread {
                    Button {
                        Task { await viewModel.markConversationRead(conversation) }
                    } label: {
                        Label(
                            String(localized: "messages.row.markRead", defaultValue: "标为已读", comment: "Mark read swipe"),
                            systemImage: "envelope.open"
                        )
                    }
                    .tint(.blue)
                }
            }

        if usesSplitInbox {
            row.tag(conversation.threadID)
        } else {
            NavigationLink(value: conversation.asMessageThread()) {
                row
            }
        }
    }

    func conversationDetail(for thread: MessageThread) -> some View {
        ConversationDetailView(
            viewModel: viewModel.conversationViewModel(for: thread),
            onOpenActivity: onOpenActivity
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
        if usesSplitInbox {
            selectedThreadID = thread.threadID
        } else {
            navigationPath.append(thread)
        }
    }
}
