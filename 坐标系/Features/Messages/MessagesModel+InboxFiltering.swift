//
//  MessagesModel+InboxFiltering.swift
//  坐标系
//
//  收件箱可见基集 / 筛选计数 / Tab 角标：与 MessagesView 列表、筛选 Menu、陌生人信箱同源。
//

import CoordinateModels
import Foundation

/// 筛选 Menu / 列表共用的条数快照（会话条数，非未读消息合计）
struct MessagesInboxFilterCounts: Equatable, Sendable {
    var all: Int
    var unread: Int
    var groups: Int
    var strangers: Int

    func conversations(for filter: MessagesInboxFilter) -> Int {
        switch filter {
        case .all: all
        case .unread: unread
        case .groups: groups
        }
    }

    /// 顶栏筛选钮角标：仅筛选生效时显示「当前筛选下列表条数」；全部时不占角标（陌生人挂在 Menu 行）
    func toolbarBadge(for filter: MessagesInboxFilter) -> Int {
        filter.isActive ? conversations(for: filter) : 0
    }
}

extension MessagesModel {
    /// 收件箱：好友会话与群聊合在同一列表（不含消息请求）
    var items: [ChatConversation] {
        conversations
            .filter { !$0.isMessageRequest }
            .sorted { lhs, rhs in
                let leftRank = Self.inboxSortRank(lhs)
                let rightRank = Self.inboxSortRank(rhs)
                if leftRank != rightRank { return leftRank < rightRank }
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    /// 收件箱排序：未读 → 在线 → 无状态点
    static func inboxSortRank(_ conversation: ChatConversation) -> Int {
        if conversation.unreadCount > 0 { return 0 }
        if conversation.kind == .direct, conversation.peerIsActive { return 1 }
        return 2
    }

    /// 收件箱可见基集：非「消息请求」，好友私聊排除已屏蔽。
    func inboxBaseItems(blockedNames: [String]) -> [ChatConversation] {
        items.filter { conversation in
            guard conversation.isFriendChat else { return true }
            return !blockedNames.contains {
                $0.caseInsensitiveCompare(conversation.title) == .orderedSame
            }
        }
    }

    /// 与下方列表同一谓词的筛选结果。
    func inboxItems(filter: MessagesInboxFilter, blockedNames: [String]) -> [ChatConversation] {
        let base = inboxBaseItems(blockedNames: blockedNames)
        guard filter.isActive else { return base }
        return base.filter { filter.matches($0) }
    }

    func inboxFilterCounts(blockedNames: [String]) -> MessagesInboxFilterCounts {
        let base = inboxBaseItems(blockedNames: blockedNames)
        return MessagesInboxFilterCounts(
            all: base.count,
            unread: base.filter { MessagesInboxFilter.unread.matches($0) }.count,
            groups: base.filter { MessagesInboxFilter.groups.matches($0) }.count,
            strangers: strangerMailboxCount
        )
    }

    /// Tab 角标（无屏蔽名单时的回退）；带屏蔽名单请用 `unreadTotal(blockedNames:)`。
    var unreadTotal: Int { unreadTotal(blockedNames: []) }

    /// Tab 角标：收件箱基集 + 陌生人信箱未读合计；静音不计入。
    func unreadTotal(blockedNames: [String]) -> Int {
        let inboxUnread = inboxBaseItems(blockedNames: blockedNames)
            .filter { !$0.isMuted }
            .reduce(0) { $0 + $1.unreadCount }
        let strangerUnread = strangerMailboxConversations
            .filter { !$0.isMuted }
            .reduce(0) { $0 + $1.unreadCount }
        return inboxUnread + strangerUnread
    }

    /// 收件箱搜索：会话匹配遵循当前筛选；聊天记录仍搜全量基集。
    func matchingConversations(
        query: String,
        filter: MessagesInboxFilter = .all,
        blockedNames: [String]
    ) -> [ChatConversation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return inboxItems(filter: filter, blockedNames: blockedNames)
            .filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.lastMessage.localizedCaseInsensitiveContains(trimmed)
                    || $0.subtitle.localizedCaseInsensitiveContains(trimmed)
                    || $0.inboxPreview.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func hasSearchResults(filter: MessagesInboxFilter = .all, blockedNames: [String]) -> Bool {
        guard isSearching else { return false }
        return !matchingConversations(
            query: searchText,
            filter: filter,
            blockedNames: blockedNames
        ).isEmpty
            || !searchHistory(query: searchText).isEmpty
    }

    var messageRequests: [ChatConversation] {
        strangerMailboxConversations
    }

    /// 陌生人信箱：陌生人发来的聊天会话（排除 `requestSource == .friend`，好友申请走 `friendRequests`）。
    var strangerMailboxConversations: [ChatConversation] {
        conversations
            .filter(\.isMessageRequest)
            .filter { ($0.requestSource ?? .directMessage) != .friend }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var pendingFriendRequestCount: Int {
        friendRequests.filter { $0.status == .pending }.count
    }

    /// 通讯录角标：仅待处理好友申请（陌生人会话角标在筛选 Menu「陌生人信箱」）。
    var requestBadgeCount: Int {
        pendingFriendRequestCount
    }

    /// 与 `StrangerMailboxSheet` 列表条数同源。
    var strangerMailboxCount: Int {
        strangerMailboxConversations.count
    }

    var pendingMessageRequests: [ChatConversation] {
        strangerMailboxConversations
    }

    var isEmptyInbox: Bool {
        items.isEmpty
    }
}
