//
//  MessagesView.swift
//  坐标系
//
//  消息收件箱：好友与群聊同一列表；左侧进通讯录；右上加号菜单。
//

import SwiftUI

private enum MessagesInboxRoute: Hashable {
    case friends
    case conversation(ChatConversation)
}

struct MessagesView: View {
    @Environment(MessagesModel.self) private var model
    @Environment(AppModel.self) private var app
    @State private var path = NavigationPath()
    @State private var showStartChat = false
    @State private var showRequests = false
    @State private var focusMessageID: ChatMessage.ID?

    private var blockedNames: [String] { Array(app.blockedUserNames) }

    private var showsEmptyOverlay: Bool {
        if model.isSearching {
            return !model.hasSearchResults(blockedNames: blockedNames)
        }
        return visibleItems.isEmpty
    }

    /// 拉黑用户的好友会话不展示
    private var visibleItems: [ChatConversation] {
        model.items.filter { conversation in
            guard conversation.isFriendChat else { return true }
            return !blockedNames.contains {
                $0.caseInsensitiveCompare(conversation.title) == .orderedSame
            }
        }
    }

    private var searchConversationMatches: [ChatConversation] {
        model.matchingConversations(query: model.searchText, blockedNames: blockedNames)
    }

    private var searchHistoryMatches: [ChatHistoryHit] {
        model.searchHistory(query: model.searchText)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            List {
                if model.isSearching {
                    searchResultsList
                } else {
                    inboxList
                }
            }
            .platformConversationListChrome()
            .opacity(showsEmptyOverlay ? 0 : 1)
            .allowsHitTesting(!showsEmptyOverlay)
            .overlay { emptyOverlay }
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $model.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: MessagesCopy.searchPrompt
            )
            .toolbar { inboxToolbar }
            .navigationDestination(for: MessagesInboxRoute.self) { route in
                switch route {
                case .friends:
                    MessagesFriendsListView(
                        onOpenChat: { name in
                            openConversation(
                                app.startDirectChat(with: name, deliverGreeting: false)
                            )
                        },
                        onOpenConversation: { conversation in
                            openConversation(model.conversations.first { $0.id == conversation.id })
                        }
                    )
                case .conversation(let conversation):
                    ConversationDetailView(
                        conversationID: conversation.id,
                        focusMessageID: focusMessageID,
                        pendingCallID: app.pendingCallID
                    )
                    .onAppear { model.markRead(conversation.id) }
                    .onDisappear { focusMessageID = nil }
                }
            }
            .sheet(isPresented: $showStartChat) {
                StartChatSheet { conversationID in
                    openConversation(model.conversations.first { $0.id == conversationID })
                }
            }
            .sheet(isPresented: $showRequests) {
                MessageRequestsSheet { conversation in
                    openConversation(model.conversations.first { $0.id == conversation.id })
                }
            }
            .confirmationDialog(
                MessagesCopy.deleteDialogTitle,
                isPresented: Binding(
                    get: { model.conversationPendingDelete != nil && path.isEmpty },
                    set: { if !$0 { model.cancelDelete() } }
                ),
                titleVisibility: .visible
            ) {
                Button(MessagesCopy.deleteDialogConfirm, role: .destructive, action: model.confirmDelete)
                Button(MessagesCopy.deleteDialogCancel, role: .cancel, action: model.cancelDelete)
            } message: {
                if let title = model.conversationPendingDelete?.title {
                    Text(MessagesCopy.deleteDialogMessage(title: title))
                }
            }
            .onChange(of: app.pendingConversationID) { _, newValue in
                guard let newValue else { return }
                openConversation(
                    model.conversations.first { $0.id == newValue },
                    focusMessageID: app.pendingFocusMessageID
                )
                app.pendingConversationID = nil
                app.pendingFocusMessageID = nil
            }
            .platformTabBarHiddenWhenPushed(path.isEmpty)
        }
    }

    @ViewBuilder
    private var inboxList: some View {
        if model.requestBadgeCount > 0 {
            Button {
                showRequests = true
            } label: {
                PlatformConversationRow(
                    title: MessagesCopy.messageRequestsInboxEntry,
                    subtitle: "待处理 \(model.requestBadgeCount) 条",
                    time: .now,
                    isUnread: true,
                    isPinned: false,
                    isMuted: false
                )
            }
            .buttonStyle(.plain)
            .platformConversationListRowChrome()
        }
        ForEach(visibleItems) { conversation in
            conversationLink(conversation)
        }
    }

    @ViewBuilder
    private var searchResultsList: some View {
        if !searchConversationMatches.isEmpty {
            Section {
                ForEach(searchConversationMatches) { conversation in
                    conversationLink(conversation)
                }
            } header: {
                PlatformMessagesSectionHeader(title: MessagesCopy.searchSectionConversations)
            }
        }

        if !searchHistoryMatches.isEmpty {
            Section {
                ForEach(searchHistoryMatches) { hit in
                    Button {
                        openConversation(
                            model.conversations.first { $0.id == hit.conversationID },
                            focusMessageID: hit.messageID
                        )
                    } label: {
                        PlatformConversationRow(
                            title: hit.conversationTitle,
                            subtitle: hit.snippet,
                            time: hit.sentAt
                        )
                    }
                    .buttonStyle(.plain)
                    .platformConversationListRowChrome()
                }
            } header: {
                PlatformMessagesSectionHeader(title: MessagesCopy.searchSectionHistory)
            }
        }
    }

    @ViewBuilder
    private func conversationLink(_ conversation: ChatConversation) -> some View {
        NavigationLink(value: MessagesInboxRoute.conversation(conversation)) {
            PlatformConversationRow(
                title: conversation.title,
                subtitle: conversation.inboxPreview,
                time: conversation.updatedAt,
                isUnread: conversation.unreadCount > 0,
                isPinned: conversation.isPinned,
                isMuted: conversation.isMuted,
                showsPresence: conversation.kind == .direct && conversation.peerIsActive
            )
        }
        .navigationLinkIndicatorVisibility(.hidden)
        .conversationSwipeActions(conversation, model: model)
        .platformConversationListRowChrome()
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if model.isSearching {
            ContentUnavailableView.search(text: model.searchText)
        } else if model.isEmptyInbox || visibleItems.isEmpty {
            ContentUnavailableView {
                Label(MessagesCopy.emptyInboxTitle, systemImage: "message")
            } description: {
                Text(MessagesCopy.emptyInboxDescription)
            } actions: {
                Button(MessagesCopy.friendsListTitle) {
                    path.append(MessagesInboxRoute.friends)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var inboxToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(MessagesCopy.friendsListTitle, systemImage: "person.crop.circle") {
                path.append(MessagesInboxRoute.friends)
            }
        }

        ToolbarItem(placement: .topBarLeading) {
            if model.requestBadgeCount > 0 {
                Button(MessagesCopy.messageRequestsInboxEntry, systemImage: "person.badge.plus") {
                    showRequests = true
                }
                .badge(model.requestBadgeCount)
            }
        }

        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Button(MessagesCopy.startChat, systemImage: "bubble.left.and.bubble.right") {
                    showStartChat = true
                }
                Button(MessagesCopy.markAllRead, systemImage: "envelope.open") {
                    model.markAllRead()
                }
                .disabled(model.unreadTotal == 0)
            } label: {
                Label(MessagesCopy.add, systemImage: "plus")
            }
        }
    }

    private func openConversation(
        _ conversation: ChatConversation?,
        focusMessageID: ChatMessage.ID? = nil
    ) {
        guard let conversation else { return }
        self.focusMessageID = focusMessageID
        model.markRead(conversation.id)
        path = NavigationPath()
        path.append(MessagesInboxRoute.conversation(conversation))
    }
}

// MARK: - Swipe

private extension View {
    func conversationSwipeActions(_ conversation: ChatConversation, model: MessagesModel) -> some View {
        self
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                Button {
                    model.togglePin(conversation.id)
                } label: {
                    Label(
                        conversation.isPinned ? MessagesCopy.unpin : MessagesCopy.pin,
                        systemImage: conversation.isPinned ? "pin.slash" : "pin"
                    )
                }
                .tint(.orange)

                Button {
                    model.toggleUnread(conversation.id)
                } label: {
                    Label(
                        conversation.unreadCount > 0 ? MessagesCopy.markRead : MessagesCopy.markUnread,
                        systemImage: conversation.unreadCount > 0 ? "envelope.open" : "envelope.badge"
                    )
                }
                .tint(.accentColor)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(MessagesCopy.delete, systemImage: "trash", role: .destructive) {
                    model.requestDelete(conversation)
                }
                Button {
                    model.toggleMute(conversation.id)
                } label: {
                    Label(
                        conversation.isMuted ? MessagesCopy.unmute : MessagesCopy.mute,
                        systemImage: conversation.isMuted ? "bell" : "bell.slash"
                    )
                }
                .tint(.secondary)
            }
    }
}

#Preview("消息") {
    MessagesView()
        .environment(MessagesModel())
}
