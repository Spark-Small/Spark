// Module: SparkActivity — Activity tab list segments (joiner + host).

import Foundation

public enum ActivityListFilter: String, Sendable, CaseIterable, Identifiable {
    case all
    case pendingReply
    case upcoming
    case hosting
    case past

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "activity.filter.all", defaultValue: "全部", comment: "Feed filter")
        case .pendingReply:
            String(localized: "activity.filter.requests", defaultValue: "活动请求", comment: "Feed filter")
        case .upcoming:
            String(localized: "activity.filter.upcoming", defaultValue: "即将参加", comment: "Feed filter")
        case .hosting:
            String(localized: "activity.filter.hosting", defaultValue: "我主办", comment: "Feed filter")
        case .past:
            String(localized: "activity.filter.past", defaultValue: "往期参加", comment: "Feed filter")
        }
    }

    /// Whether the Activity inbox should surface inbox request cards (invites / changes / waitlist).
    public var showsInboxActionItems: Bool {
        self == .pendingReply
    }
}

public enum ActivityInboxListPresentation {
    /// Hides feed rows already represented by inbox request cards on the 活动请求 segment.
    public static func listItems(
        from feedItems: [ActivityItem],
        filter: ActivityListFilter,
        requestActivityIDs: Set<String>
    ) -> [ActivityItem] {
        guard filter == .pendingReply, !requestActivityIDs.isEmpty else { return feedItems }
        return feedItems.filter { !requestActivityIDs.contains($0.id) }
    }
}

public enum ActivityListFiltering {
    public static func matches(_ item: ActivityItem, filter: ActivityListFilter, now: Date = Date()) -> Bool {
        switch filter {
        case .all:
            true
        case .pendingReply:
            item.rsvpStatus == .invited && item.lifecycleStatus == .scheduled
        case .upcoming:
            item.rsvpStatus.hasGroupChatAccess
                && item.rsvpStatus != .host
                && item.lifecycleStatus == .scheduled
                && (item.startsAt.map { $0 > now } ?? true)
        case .hosting:
            item.rsvpStatus == .host
        case .past:
            item.lifecycleStatus == .ended
                && item.rsvpStatus.hasGroupChatAccess
                && item.rsvpStatus != .host
        }
    }
}
