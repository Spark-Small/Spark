//
//  MessagesView.swift
//  坐标系
//
//  消息收件箱：会话列表为主转化；通讯录管关系与好友请求（角标）。
//

import SwiftUI
import CoordinateModels

private enum MessagesInboxRoute: Hashable {
    case friends
    case conversation(ChatConversation)
}

private enum MessagesInboxFilter: String, CaseIterable, Identifiable {
    case all
    case friends
    case activityGroups
    case clubs

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: MessagesCopy.filterAll
        case .friends: MessagesCopy.filterFriends
        case .activityGroups: MessagesCopy.filterActivityGroups
        case .clubs: MessagesCopy.filterClubGroups
        }
    }
}

struct MessagesView: View {
    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var navigation = TabNavigationState()
    @State private var focusMessageID: ChatMessage.ID?
    @State private var inboxFilter: MessagesInboxFilter = .all

    private var blockedNames: [String] { Array(app.blockedUserNames) }

    private var showsEmptyOverlay: Bool {
        if model.isSearching {
            return !model.hasSearchResults(blockedNames: blockedNames)
        }
        return visibleItems.isEmpty
    }

    /// 拉黑用户的好友会话不展示
    private var visibleItems: [ChatConversation] {
        filteredItems(model.items.filter { conversation in
            guard conversation.isFriendChat else { return true }
            return !blockedNames.contains {
                $0.caseInsensitiveCompare(conversation.title) == .orderedSame
            }
        })
    }

    private func filteredItems(_ items: [ChatConversation]) -> [ChatConversation] {
        switch inboxFilter {
        case .all:
            return items
        case .friends:
            return items.filter(\.isFriendChat)
        case .activityGroups:
            return items.filter(\.isActivityGroup)
        case .clubs:
            return items.filter(\.isCircleGroup)
        }
    }

    private var searchConversationMatches: [ChatConversation] {
        model.matchingConversations(query: model.searchText, blockedNames: blockedNames)
    }

    private var searchHistoryMatches: [ChatHistoryHit] {
        model.searchHistory(query: model.searchText)
    }

    private var hasActivityGroupConversations: Bool {
        model.items.contains(where: \.isActivityGroup)
    }

    private var showsActivityGroupInboxHint: Bool {
        !model.isSearching
            && hasActivityGroupConversations
            && inboxFilter == .all
            && !showsEmptyOverlay
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            List {
                if model.isSearching {
                    searchResultsList
                } else {
                    inboxList
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
            .tint(PlatformAction.cloverPurple)
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
                Button(MessagesCopy.deleteDialogConfirm, role: .destructive, action: model.confirmDelete)
                Button(MessagesCopy.deleteDialogCancel, role: .cancel, action: model.cancelDelete)
            } message: {
                if let title = model.conversationPendingDelete?.title {
                    Text(MessagesCopy.deleteDialogMessage(title: title))
                }
            }
            .onAppear { consumePendingConversationOpen() }
            .onChange(of: app.pendingConversationID) { _, _ in
                consumePendingConversationOpen()
            }
        }
        .tabNavigationState(navigation)
    }

    @ViewBuilder
    private var inboxList: some View {
        if showsActivityGroupInboxHint {
            Section {
                HStack(alignment: .center, spacing: PlatformMetrics.cardInfoSpacing) {
                    Label(MessagesCopy.activityGroupInboxHint, systemImage: "person.3")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: PlatformMetrics.minContentGap)
                    Button(MessagesCopy.activityGroupInboxFilterAction) {
                        inboxFilter = .activityGroups
                    }
                    .font(.footnote.weight(.semibold))
                }
                .accessibilityElement(children: .combine)
            }
        }

        if !model.isSearching {
            Section {
                Picker("筛选", selection: $inboxFilter) {
                    ForEach(MessagesInboxFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
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
                .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        } else if model.isEmptyInbox || visibleItems.isEmpty {
            ContentUnavailableView {
                Label(MessagesCopy.emptyInboxTitle, systemImage: "message")
            } description: {
                Text(MessagesCopy.emptyInboxDescription)
            } actions: {
                Button(MessagesCopy.emptyInboxBrowseActivities) {
                    app.selectedTab = .activities
                }
                .activityPrimaryCTA(controlSize: .large)

                Button(MessagesCopy.emptyInboxMeetBuddies) {
                    app.selectedTab = .buddies
                    app.buddies.showSocialPage()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                Button(MessagesCopy.emptyInboxJoinClubs) {
                    app.openClubDiscover()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(MessagesCopy.friendsListTitle, systemImage: "person.crop.circle") {
                navigation.path.append(MessagesInboxRoute.friends)
            }
            .badge(model.requestBadgeCount)
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
    let app = AppModel.preview
    MessagesView()
        .environment(app.messages)
}
