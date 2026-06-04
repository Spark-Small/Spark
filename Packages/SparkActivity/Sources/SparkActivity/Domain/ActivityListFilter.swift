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
            String(localized: "activity.filter.pending", defaultValue: "待回复", comment: "Feed filter")
        case .upcoming:
            String(localized: "activity.filter.upcoming", defaultValue: "即将参加", comment: "Feed filter")
        case .hosting:
            String(localized: "activity.filter.hosting", defaultValue: "我主办", comment: "Feed filter")
        case .past:
            String(localized: "activity.filter.past", defaultValue: "往期参加", comment: "Feed filter")
        }
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
