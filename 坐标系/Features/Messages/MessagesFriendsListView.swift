//
//  MessagesFriendsListView.swift
//  坐标系
//
//  消息「通讯录」：UITableView 原生 sectionIndex + 整行 UIListContentConfiguration。
//

import SwiftUI
import UIKit
import CoordinateModels

struct MessagesFriendsListView: View {
    var onOpenChat: (String) -> Void
    var onOpenConversation: (ChatConversation) -> Void

    @Environment(MessagesModel.self) private var model
    @Environment(BuddiesModel.self) private var buddies
    @Environment(AppModel.self) private var app
    @State private var searchText = ""
    @State private var profileRoute: FriendProfileRoute?
    @State private var showRequests = false
    @State private var showStartChat = false
    @State private var showAddFriendByUID = false

    private var friends: [FriendListEntry] {
        MessagesContactRoster.nicknames(
            conversations: model.conversations,
            inviteNicknames: buddies.inviteRecords.map(\.nickname),
            bookingNicknames: buddies.bookingRecords.map(\.companionNickname),
            blockedNames: Array(app.blockedUserNames)
        )
        .map(FriendListEntry.init(name:))
        .sorted {
            model.displayName(for: $0.name).localizedStandardCompare(model.displayName(for: $1.name))
                == .orderedAscending
        }
    }

    private var filteredFriends: [FriendListEntry] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return friends }
        return friends.filter {
            $0.name.localizedCaseInsensitiveContains(trimmed)
                || model.displayName(for: $0.name).localizedCaseInsensitiveContains(trimmed)
                || model.remark(for: $0.name).localizedCaseInsensitiveContains(trimmed)
                || UserPublicDirectory.uid(forNickname: $0.name).contains(UserPublicID.normalize(trimmed))
        }
    }

    private var tableSections: [PlatformContactsTableSection] {
        FriendSection.build(from: filteredFriends, displayName: model.displayName(for:))
            .map { section in
                PlatformContactsTableSection(
                    title: section.title,
                    collationIndex: section.collationIndex,
                    items: section.friends.map { friend in
                        PlatformContactsTableItem(
                            id: friend.id,
                            nickname: friend.name,
                            displayName: model.displayName(for: friend.name),
                            isActive: isActive(friend.name)
                        )
                    }
                )
            }
    }

    private var showsEmptyOverlay: Bool {
        friends.isEmpty || filteredFriends.isEmpty
    }

    var body: some View {
        Group {
            if showsEmptyOverlay {
                emptyOverlay
            } else {
                PlatformContactsTableView(
                    sections: tableSections,
                    onOpenChat: onOpenChat,
                    onViewProfile: { name in
                        profileRoute = FriendProfileRoute(name: name)
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(Color(.systemBackground))
        .navigationTitle(MessagesCopy.friendsListTitle)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: MessagesCopy.friendsListSearch
        )
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(MessagesCopy.startChat, systemImage: "bubble.left.and.bubble.right") {
                        showStartChat = true
                    }
                    Button(MessagesCopy.addFriendByUID, systemImage: "person.badge.plus") {
                        showAddFriendByUID = true
                    }
                    Button(MessagesCopy.inviteFriends, systemImage: "square.and.arrow.up") {
                        MessagesInviteFriends.presentSystemShare()
                    }
                    Button(MessagesCopy.messageRequestsTitle, systemImage: "person.crop.circle.badge.questionmark") {
                        showRequests = true
                    }
                    Button(MessagesCopy.markAllRead, systemImage: "envelope.open") {
                        model.markAllRead()
                    }
                    .disabled(model.unreadTotal == 0)
                } label: {
                    Label(MessagesCopy.add, systemImage: "plus")
                }
                .badge(model.requestBadgeCount)
            }
        }
        .sheet(isPresented: $showStartChat) {
            StartChatSheet { conversationID in
                if let conversation = model.conversations.first(where: { $0.id == conversationID }) {
                    onOpenConversation(conversation)
                }
            }
            .platformHiddenTabBar()
        }
        .sheet(isPresented: $showRequests) {
            MessageRequestsSheet(onOpen: onOpenConversation)
                .platformHiddenTabBar()
        }
        .sheet(isPresented: $showAddFriendByUID) {
            AddFriendByUIDSheet { nickname in
                onOpenChat(nickname)
            }
            .platformHiddenTabBar()
        }
        .navigationDestination(item: $profileRoute) { route in
            FriendProfileDetailView(nickname: route.name)
                .toolbarVisibility(.hidden, for: .tabBar)
        }
    }

    private func isActive(_ name: String) -> Bool {
        model.conversations.contains {
            $0.isFriendChat
                && $0.title.caseInsensitiveCompare(name) == .orderedSame
                && $0.peerIsActive
        }
    }

    @ViewBuilder
    private var emptyOverlay: some View {
        if friends.isEmpty {
            ContentUnavailableView {
                Label(MessagesCopy.friendsListEmptyTitle, systemImage: "person.crop.circle")
            } description: {
                Text(MessagesCopy.friendsListEmptyDescription)
            } actions: {
                Button(MessagesCopy.inviteFriends) {
                    MessagesInviteFriends.presentSystemShare()
                }
                .activityPrimaryCTA(controlSize: .large)
                Button(MessagesCopy.addFriendByUID) {
                    showAddFriendByUID = true
                }
                .activitySecondaryCTA(controlSize: .large)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        } else {
            ContentUnavailableView.search(text: searchText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        }
    }
}

// MARK: - Model

private struct FriendProfileRoute: Identifiable, Hashable {
    var id: String { name.lowercased() }
    let name: String
}

private struct FriendListEntry: Identifiable {
    var id: String { name.lowercased() }
    let name: String
}

private struct FriendSection: Identifiable {
    var id: String { title }
    let title: String
    let collationIndex: Int
    let friends: [FriendListEntry]

    @MainActor
    static func build(
        from friends: [FriendListEntry],
        displayName: (String) -> String
    ) -> [FriendSection] {
        guard !friends.isEmpty else { return [] }
        let collation = UILocalizedIndexedCollation.current()
        var buckets = Array(repeating: [FriendListEntry](), count: collation.sectionTitles.count)

        for friend in friends {
            let index = collation.section(
                for: CollationNameBox(displayName(friend.name)),
                collationStringSelector: #selector(getter: CollationNameBox.name)
            )
            let clamped = min(max(index, 0), buckets.count - 1)
            buckets[clamped].append(friend)
        }

        return collation.sectionTitles.enumerated().compactMap { collationIndex, title in
            let entries = buckets[collationIndex]
            guard !entries.isEmpty else { return nil }
            let sorted = collation.sortedArray(
                from: entries.map { CollationNameBox(displayName($0.name)) },
                collationStringSelector: #selector(getter: CollationNameBox.name)
            ) as? [CollationNameBox] ?? []
            let order = Dictionary(
                uniqueKeysWithValues: sorted.enumerated().map { ($0.element.name.lowercased(), $0.offset) }
            )
            let orderedFriends = entries.sorted {
                let lhs = displayName($0.name).lowercased()
                let rhs = displayName($1.name).lowercased()
                return (order[lhs] ?? 0) < (order[rhs] ?? 0)
            }
            return FriendSection(
                title: title,
                collationIndex: collationIndex,
                friends: orderedFriends
            )
        }
    }
}

/// `UILocalizedIndexedCollation` 需要带 `@objc` 字符串属性的对象
private final class CollationNameBox: NSObject {
    @objc let name: String
    init(_ name: String) { self.name = name }
}
