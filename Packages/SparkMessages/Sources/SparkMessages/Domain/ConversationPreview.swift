// Module: SparkMessages — Unified inbox row for DM and activity group chats.

import Foundation

public enum ConversationKind: String, Sendable, Equatable {
    case dm
    case groupChat
}

public struct ConversationPreview: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let threadID: MessageThreadID
    public let kind: ConversationKind
    public let displayName: String
    public let lastMessagePreview: String
    public let lastMessageAt: Date
    public let unreadCount: Int
    public let dmPartner: InboxUserProfile?
    public let isPartnerOnline: Bool?
    public let activity: InboxActivitySummary?
    public let memberCount: Int?
    public let isArchived: Bool

    public init(
        threadID: MessageThreadID,
        kind: ConversationKind,
        displayName: String,
        lastMessagePreview: String,
        lastMessageAt: Date,
        unreadCount: Int,
        dmPartner: InboxUserProfile? = nil,
        isPartnerOnline: Bool? = nil,
        activity: InboxActivitySummary? = nil,
        memberCount: Int? = nil,
        isArchived: Bool = false
    ) {
        self.id = threadID.rawValue
        self.threadID = threadID
        self.kind = kind
        self.displayName = displayName
        self.lastMessagePreview = lastMessagePreview
        self.lastMessageAt = lastMessageAt
        self.unreadCount = unreadCount
        self.dmPartner = dmPartner
        self.isPartnerOnline = isPartnerOnline
        self.activity = activity
        self.memberCount = memberCount
        self.isArchived = isArchived
    }

    public var hasUnread: Bool { unreadCount > 0 }

    public var lastMessageRelativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastMessageAt, relativeTo: Date())
    }

    public func asMessageThread() -> MessageThread {
        MessageThread(
            threadID: threadID,
            peerDisplayName: displayName,
            lastMessagePreview: lastMessagePreview,
            lastActivityAt: lastMessageAt,
            unreadCount: unreadCount
        )
    }
}

public struct MatchPreview: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let user: InboxUserProfile
    public let matchedAt: Date
    public let threadID: MessageThreadID?

    public init(id: String, user: InboxUserProfile, matchedAt: Date, threadID: MessageThreadID? = nil) {
        self.id = id
        self.user = user
        self.matchedAt = matchedAt
        self.threadID = threadID
    }
}
