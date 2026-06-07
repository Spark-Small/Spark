// Module: SparkMessages — Inbox section ordering rules.

import Foundation

enum MessagesInboxSorting {
    /// Synthetic thread id for matches that do not yet have a DM thread.
    static func pendingMatchThreadID(for match: MatchPreview) -> MessageThreadID {
        match.threadID ?? MessageThreadID("pending_match_\(match.id)")
    }

    static func isPendingMatchThreadID(_ threadID: MessageThreadID) -> Bool {
        threadID.rawValue.hasPrefix("pending_match_")
    }

    static func conversationPreview(from match: MatchPreview) -> ConversationPreview {
        ConversationPreview(
            threadID: pendingMatchThreadID(for: match),
            kind: .dm,
            displayName: match.user.displayName,
            lastMessagePreview: String(
                localized: "messages.match.new.preview",
                defaultValue: "新配对，打个招呼",
                comment: "New match row preview"
            ),
            lastMessageAt: match.matchedAt,
            unreadCount: 1,
            dmPartner: match.user,
            isPartnerOnline: false
        )
    }

    static func unifiedDMConversations(
        matches: [MatchPreview],
        conversations: [ConversationPreview]
    ) -> [ConversationPreview] {
        let existingPartnerIDs = Set(conversations.compactMap(\.dmPartner?.id))
        let matchRows = matches
            .filter { !existingPartnerIDs.contains($0.user.id) }
            .map(conversationPreview(from:))
        return dmConversations(matchRows + conversations)
    }

    static func dmConversations(_ items: [ConversationPreview]) -> [ConversationPreview] {
        conversationListOrder(items)
    }

    static func visibleGroupChats(_ items: [ConversationPreview]) -> [ConversationPreview] {
        conversationListOrder(items.filter(isVisibleGroupChat))
    }

    /// Shared inbox ordering: unread first, then most recent activity.
    static func conversationListOrder(_ items: [ConversationPreview]) -> [ConversationPreview] {
        items.sorted {
            if $0.hasUnread != $1.hasUnread { return $0.hasUnread && !$1.hasUnread }
            return $0.lastMessageAt > $1.lastMessageAt
        }
    }

    static func isVisibleGroupChat(_ conversation: ConversationPreview) -> Bool {
        guard conversation.kind == .groupChat else { return false }
        guard !conversation.isArchived else { return false }
        guard let lifecycle = conversation.activity?.lifecycle else { return true }
        return lifecycle != .ended
    }

}
