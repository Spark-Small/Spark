//
//  MessagesView.swift
//  坐标系
//
//  消息收件箱：会话列表为主转化；顶栏筛选 / 通讯录。
//

import SwiftUI
import CoordinateModels

enum MessagesInboxRoute: Hashable {
    case friends
    /// 只存 ID，避免会话可变字段进 NavigationPath 导致栈身份抖动。
    case conversation(ChatConversation.ID)
}

struct MessagesView: View {
    @Environment(MessagesModel.self) var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) var app
    @State var navigation = TabNavigationState()
    @State private var focusByConversation: [ChatConversation.ID: ChatMessage.ID] = [:]
    @State private var routedPendingCallID: CallSessionRecord.ID?
    @State private var routedCallConversationID: ChatConversation.ID?
    @State var inboxFilter: MessagesInboxFilter = .all
    @State var showStrangerMailbox = false

    var blockedNames: [String] { Array(app.blockedUserNames) }

    private var showsEmptyOverlay: Bool {
        if model.isSearching {
            return !model.hasSearchResults(filter: inboxFilter, blockedNames: blockedNames)
        }
        return visibleItems.isEmpty
    }

    private var inboxFilterCounts: MessagesInboxFilterCounts {
        model.inboxFilterCounts(blockedNames: blockedNames)
    }

    /// 与筛选 Menu 角标同源（`inboxItems`）。
    var visibleItems: [ChatConversation] {
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
        model.matchingConversations(
            query: model.searchText,
            filter: inboxFilter,
            blockedNames: blockedNames
        )
    }

    private var searchHistoryMatches: [ChatHistoryHit] {
        model.searchHistory(query: model.searchText)
    }

    var isFilterEmptyOnly: Bool {
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
                case .conversation(let conversationID):
                    ConversationDetailView(
                        conversationID: conversationID,
                        focusMessageID: focusByConversation[conversationID],
                        pendingCallID: routedPendingCallID
                            .flatMap { callID in
                                routedCallConversationID == conversationID ? callID : nil
                            },
                        onOpenCircleInfo: { circle in
                            navigation.openCircle(circle)
                        }
                    )
                    .toolbarVisibility(.hidden, for: .tabBar)
                    .onAppear { model.markRead(conversationID) }
                    .onDisappear {
                        focusByConversation[conversationID] = nil
                        if routedCallConversationID == conversationID {
                            routedPendingCallID = nil
                            routedCallConversationID = nil
                        }
                    }
                }
            }
            .circleBrowseStackChrome(
                buddies: buddies,
                messages: model,
                memberName: app.user.name,
                blockedUserNames: app.blockedUserNames,
                onBrowseBuddies: {
                    app.pendingBuddiesRoute = .socialBrowse
                    app.selectedTab = .buddies
                },
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
        NavigationLink(value: MessagesInboxRoute.conversation(conversation.id)) {
            PlatformConversationRow(
                title: conversation.title,
                subtitle: conversation.inboxListSecondary,
                time: conversation.updatedAt,
                isUnread: conversation.unreadCount > 0 && !conversation.isMuted,
                isPinned: conversation.isPinned,
                isMuted: conversation.isMuted,
                showsPresence: conversation.kind == .direct && conversation.peerIsActive
            )
        }
        .navigationLinkIndicatorVisibility(.hidden)
        .conversationSwipeActions(conversation, model: model)
        .platformConversationListRowChrome()
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
        if let focusMessageID {
            focusByConversation[conversation.id] = focusMessageID
        } else {
            focusByConversation[conversation.id] = nil
        }
        model.markRead(conversation.id)
        navigation.reset()
        navigation.path.append(MessagesInboxRoute.conversation(conversation.id))
    }

    private func consumePendingConversationOpen() {
        guard let id = app.pendingConversationID else { return }
        let focus = app.pendingFocusMessageID
        let callID = app.pendingCallID
        guard model.conversations.contains(where: { $0.id == id }) else {
            // 会话缺失时一并清掉通话意图，避免孤儿 pendingCall 挂到下一场会话。
            app.pendingConversationID = nil
            app.pendingFocusMessageID = nil
            app.pendingCallID = nil
            return
        }
        app.pendingConversationID = nil
        app.pendingFocusMessageID = nil
        app.pendingCallID = nil
        routedPendingCallID = callID
        routedCallConversationID = id
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
