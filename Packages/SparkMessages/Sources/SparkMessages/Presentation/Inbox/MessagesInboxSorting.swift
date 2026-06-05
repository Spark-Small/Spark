// Module: SparkMessages — Inbox section ordering rules.

import Foundation

enum MessagesInboxSorting {
    static func dmConversations(_ items: [ConversationPreview]) -> [ConversationPreview] {
        items.sorted {
            if $0.hasUnread != $1.hasUnread { return $0.hasUnread && !$1.hasUnread }
            return $0.lastMessageAt > $1.lastMessageAt
        }
    }

    static func activeGroupChats(_ items: [ConversationPreview]) -> [ConversationPreview] {
        items.sorted {
            let left = $0.activity?.startsAt ?? $0.lastMessageAt
            let right = $1.activity?.startsAt ?? $1.lastMessageAt
            return left < right
        }
    }
}
