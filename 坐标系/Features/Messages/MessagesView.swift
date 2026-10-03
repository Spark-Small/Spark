//
//  MessagesView.swift
//  坐标系
//
//  消息收件箱：会话列表为主转化；顶栏筛选 / 新聊天 / 通讯录分组。
//

import SwiftUI
import CoordinateModels

private enum MessagesInboxRoute: Hashable {
    case friends
    case conversation(ChatConversation)
}

struct MessagesView: View {
    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var navigation = TabNavigationState()
    @State private var focusMessageID: ChatMessage.ID?
    @State private var inboxFilter: MessagesInboxFilter = .all
    @State private var showStrangerMailbox = false

    private var blockedNames: [String] { Array(app.blockedUserNames) }

    private var showsEmptyOverlay: Bool {
        if model.isSearching {
            return !model.hasSearchResults(blockedNames: blockedNames)
        }
        return visibleItems.isEmpty
    }

    private var inboxFilterCounts: MessagesInboxFilterCounts {
        model.inboxFilterCounts(blockedNames: blockedNames)
    }

    /// 与筛选 Menu 角标同源（`inboxItems`）。
    private var visibleItems: [ChatConversation] {
        model.inboxItems(filter: inboxFilter, blockedNames: blockedNames)
    }

    private var pinnedItems: [ChatConversation] {
        visibleItems.filter(\.isPinned)
    }

    private var unpinnedItems: [ChatConversation] {
        visibleItems.filter { !$0.isPinned }
    }

    /// 置顶靠前，仍用同一套 plain 行 chrome（勿拆 Section，避免分节「框感」）。
    private var inboxSortedItems: [ChatConversation] {
        pinnedItems + unpinnedItems
    }

    private var searchConversationMatches: [ChatConversation] {
        model.matchingConversations(query: model.searchText, blockedNames: blockedNames)
    }

    private var searchHistoryMatches: [ChatHistoryHit] {
        model.searchHistory(query: model.searchText)
    }

    private var isFilterEmptyOnly: Bool {
        !model.isSearching
            && !model.isEmptyInbox
            && visibleItems.isEmpty
            && inboxFilter != .all
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            List {
                Group {
                    if model.isSearching {
                        searchResultsList
                    } else {
                        inboxList
                    }
                }
            }
            .platformConversationListChrome()
            .platformTabRootListChrome(title: MessagesCopy.rootTitle)
            .opacity(showsEmptyOverlay ? 0 : 1)
            .allowsHitTesting(!showsEmptyOverlay)
            .overlay { emptyOverlay }
            .searchable(
                text: $model.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: MessagesCopy.searchPrompt
            )
            .platformTabRootToolbar { tabToolbar }
            .refreshable { await model.reloadFromRepository() }
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
                    .toolbarVisibility(.hidden, for: .tabBar)
                case .conversation(let conversation):
                    ConversationDetailView(
                        conversationID: conversation.id,
                        focusMessageID: focusMessageID,
                        pendingCallID: app.pendingCallID,
                        onOpenCircleInfo: { circle in
                            navigation.openCircle(circle)
                        }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .onAppear { model.markRead(conversation.id) }
                    .onDisappear { focusMessageID = nil }
                }
            }
            .circleBrowseStackChrome(
                buddies: buddies,
                messages: model,
                memberName: app.user.name,
                blockedUserNames: app.blockedUserNames,
                onBrowseBuddies: { app.selectedTab = .buddies },
                openCircle: { navigation.openCircle($0) },
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .alert(
                MessagesCopy.deleteDialogTitle,
                isPresented: Binding(
                    get: { model.conversationPendingDelete != nil && navigation.isEmpty },
                    set: { if !$0 { model.cancelDelete() } }
                )
            ) {
                Button(MessagesCopy.deleteDialogConfirm, role: .destructive) {
                    model.confirmDelete()
                }
                Button(MessagesCopy.deleteDialogCancel, role: .cancel) {
                    model.cancelDelete()
                }
            } message: {
                if let title = model.conversationPendingDelete?.title {
                    Text(MessagesCopy.deleteDialogMessage(title: title))
                }
            }
            .onAppear { consumePendingConversationOpen() }
            .onChange(of: app.pendingConversationID) { _, _ in
                consumePendingConversationOpen()
            }
            .sheet(isPresented: $showStrangerMailbox) {
                StrangerMailboxSheet { conversation in
                    openConversation(conversation)
                }
                .platformHiddenTabBar()
            }
        }
        .tabNavigationState(navigation)
    }

    @ViewBuilder
    private var inboxList: some View {
        ForEach(inboxSortedItems) { conversation in
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
                subtitle: conversation.inboxListSecondary,
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
                .frame(maxWidth: .infinity)
        } else if isFilterEmptyOnly {
            ContentUnavailableView {
                Label(MessagesCopy.filterEmptyTitle, systemImage: "line.3.horizontal.decrease.circle")
            } description: {
                Text(MessagesCopy.filterEmptyDescription)
            } actions: {
                Button(MessagesCopy.filterEmptyShowAll) {
                    inboxFilter = .all
                }
                .activityPrimaryCTA(controlSize: .large)
            }
            .frame(maxWidth: .infinity)
        } else if model.isEmptyInbox || visibleItems.isEmpty {
            ContentUnavailableView {
                Label(MessagesCopy.emptyInboxTitle, systemImage: "message")
            } description: {
                Text(MessagesCopy.emptyInboxDescription)
            } actions: {
                Button(MessagesCopy.friendsListTitle) {
                    navigation.path.append(MessagesInboxRoute.friends)
                }
                .activityPrimaryCTA(controlSize: .large)

                Button(MessagesCopy.emptyInboxBrowseActivities) {
                    app.selectedTab = .activities
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(MessagesCopy.emptyInboxMeetBuddies) {
                    app.selectedTab = .buddies
                    app.buddies.showSocialPage()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            MessagesInboxFilterMenu(
                filter: $inboxFilter,
                counts: inboxFilterCounts,
                onOpenStrangerMailbox: { showStrangerMailbox = true },
                onMarkAllRead: { model.markAllRead() }
            )
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(MessagesCopy.friendsListTitle, systemImage: "person.crop.circle") {
                navigation.path.append(MessagesInboxRoute.friends)
            }
            .badge(model.requestBadgeCount)
            .platformNavigationBarItemChrome()
            .accessibilityHint(MessagesCopy.friendsListHint)
        }
    }

    private func openConversation(
        _ conversation: ChatConversation?,
        focusMessageID: ChatMessage.ID? = nil
    ) {
        guard let conversation else { return }
        self.focusMessageID = focusMessageID
        model.markRead(conversation.id)
        navigation.reset()
        navigation.path.append(MessagesInboxRoute.conversation(conversation))
    }

    private func consumePendingConversationOpen() {
        guard let id = app.pendingConversationID else { return }
        let focus = app.pendingFocusMessageID
        app.pendingConversationID = nil
        app.pendingFocusMessageID = nil
        openConversation(
            model.conversations.first { $0.id == id },
            focusMessageID: focus
        )
    }
}

#Preview("消息") {
    let app = AppModel.preview
    MessagesView()
        .environment(app.messages)
}
