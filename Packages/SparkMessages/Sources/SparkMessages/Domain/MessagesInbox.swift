// Module: SparkMessages — Aggregated unified inbox payload.

import Foundation

public struct MessagesInbox: Sendable, Equatable {
    public let actionItems: [ActionItem]
    public let unmessagedMatches: [MatchPreview]
    public let dmConversations: [ConversationPreview]
    public let activeGroupChats: [ConversationPreview]
    public let archivedGroupChats: [ConversationPreview]

    public init(
        actionItems: [ActionItem] = [],
        unmessagedMatches: [MatchPreview] = [],
        dmConversations: [ConversationPreview] = [],
        activeGroupChats: [ConversationPreview] = [],
        archivedGroupChats: [ConversationPreview] = []
    ) {
        self.actionItems = ActionItem.sorted(actionItems)
        self.unmessagedMatches = unmessagedMatches
        self.dmConversations = dmConversations
        self.activeGroupChats = activeGroupChats
        self.archivedGroupChats = archivedGroupChats
    }

    public var allThreads: [MessageThread] {
        (dmConversations + activeGroupChats + archivedGroupChats).map { $0.asMessageThread() }
    }

    public var isCompletelyEmpty: Bool {
        actionItems.isEmpty
            && unmessagedMatches.isEmpty
            && dmConversations.isEmpty
            && activeGroupChats.isEmpty
            && archivedGroupChats.isEmpty
    }
}

public struct ConversationContext: Sendable, Equatable {
    public let sharedActivities: [InboxActivitySummary]
    public let relationshipStatus: String

    public init(sharedActivities: [InboxActivitySummary], relationshipStatus: String) {
        self.sharedActivities = sharedActivities
        self.relationshipStatus = relationshipStatus
    }
}
