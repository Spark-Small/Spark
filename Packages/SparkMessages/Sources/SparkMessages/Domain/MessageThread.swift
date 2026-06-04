// Module: SparkMessages — Inbox thread summary.

import Foundation

public struct MessageThread: Identifiable, Hashable, Sendable, Equatable {
    public var id: MessageThreadID { threadID }
    public let threadID: MessageThreadID
    public let peerDisplayName: String
    public let lastMessagePreview: String
    public let lastActivityAt: Date
    public let unreadCount: Int

    public init(
        threadID: MessageThreadID,
        peerDisplayName: String,
        lastMessagePreview: String,
        lastActivityAt: Date,
        unreadCount: Int
    ) {
        self.threadID = threadID
        self.peerDisplayName = peerDisplayName
        self.lastMessagePreview = lastMessagePreview
        self.lastActivityAt = lastActivityAt
        self.unreadCount = unreadCount
    }
}
