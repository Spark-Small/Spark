// Module: SparkMessages — Activity metadata shown in messages inbox and chat.

import Foundation

public enum InboxActivityLifecycle: String, Sendable, Equatable {
    case upcoming
    case ongoing
    case ended
}

public struct InboxActivitySummary: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let coverURL: URL?
    public let startsAt: Date
    public let attendeeCount: Int
    public let lifecycle: InboxActivityLifecycle

    public init(
        id: String,
        title: String,
        coverURL: URL? = nil,
        startsAt: Date,
        attendeeCount: Int,
        lifecycle: InboxActivityLifecycle = .upcoming
    ) {
        self.id = id
        self.title = title
        self.coverURL = coverURL
        self.startsAt = startsAt
        self.attendeeCount = attendeeCount
        self.lifecycle = lifecycle
    }

    public var formattedDate: String {
        startsAt.formatted(date: .abbreviated, time: .shortened)
    }

    public var formattedDateShort: String {
        startsAt.formatted(.dateTime.month(.abbreviated).day().hour().minute())
    }

    public var countdownText: String {
        switch lifecycle {
        case .ongoing:
            return String(localized: "messages.activity.ongoing", defaultValue: "活动进行中", comment: "Event in progress")
        case .ended:
            return String(localized: "messages.activity.ended", defaultValue: "活动已结束", comment: "Event ended")
        case .upcoming:
            let interval = startsAt.timeIntervalSinceNow
            if interval <= 0 {
                return String(localized: "messages.activity.ongoing", defaultValue: "活动进行中", comment: "Event in progress")
            }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            let relative = formatter.localizedString(for: startsAt, relativeTo: Date())
            let format = String(
                localized: "messages.activity.countdown",
                defaultValue: "距活动开始还有 %@",
                comment: "Countdown; %@ is relative time"
            )
            return String(format: format, locale: .current, relative)
        }
    }
}
