// Module: SparkMessages — Inbox action cards requiring user response.

import Foundation

public struct ActivityInvite: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let activity: InboxActivitySummary
    public let inviter: InboxUserProfile

    public init(id: String, activity: InboxActivitySummary, inviter: InboxUserProfile) {
        self.id = id
        self.activity = activity
        self.inviter = inviter
    }
}

public struct ActivityChange: Identifiable, Hashable, Sendable, Equatable {
    public enum ChangeKind: String, Sendable, Equatable {
        case rescheduled
        case cancelled
    }

    public let id: String
    public let kind: ChangeKind
    public let activity: InboxActivitySummary
    public let hostName: String
    public let previousScheduleLine: String

    public init(
        id: String,
        kind: ChangeKind,
        activity: InboxActivitySummary,
        hostName: String,
        previousScheduleLine: String
    ) {
        self.id = id
        self.kind = kind
        self.activity = activity
        self.hostName = hostName
        self.previousScheduleLine = previousScheduleLine
    }
}

public enum ActionItemKind: Hashable, Sendable, Equatable {
    case activityInvite(ActivityInvite)
    case activityChanged(ActivityChange)
    case waitlistPromoted(InboxActivitySummary)
}

public struct ActionItem: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let kind: ActionItemKind
    public let priority: Int
    public let createdAt: Date

    public init(id: String, kind: ActionItemKind, priority: Int, createdAt: Date) {
        self.id = id
        self.kind = kind
        self.priority = priority
        self.createdAt = createdAt
    }

    public static func sorted(_ items: [ActionItem]) -> [ActionItem] {
        items.sorted {
            if $0.priority != $1.priority { return $0.priority < $1.priority }
            return $0.createdAt > $1.createdAt
        }
    }
}
