// Module: SparkActivity — Activity list row model.

import Foundation

public struct ActivityItem: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    /// Legacy one-line hint when `starts_at` is absent on older payloads.
    public let summary: String
    public let category: String
    public let startsAt: Date?
    public let endsAt: Date?
    public let locationName: String
    public let hostDisplayName: String
    public let hostID: String?
    public let attendeeCount: Int
    public let capacity: Int?
    public let rsvpStatus: ActivityRSVPStatus
    public let lifecycleStatus: ActivityLifecycleStatus
    /// When set, detail screen can open this messages thread (`MessageThreadID` raw value).
    public let conversationThreadID: String?

    public init(
        id: String,
        title: String,
        summary: String,
        category: String,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        locationName: String = "",
        hostDisplayName: String = "",
        hostID: String? = nil,
        attendeeCount: Int = 0,
        capacity: Int? = nil,
        rsvpStatus: ActivityRSVPStatus = .invited,
        lifecycleStatus: ActivityLifecycleStatus = .scheduled,
        conversationThreadID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.locationName = locationName
        self.hostDisplayName = hostDisplayName
        self.hostID = hostID
        self.attendeeCount = attendeeCount
        self.capacity = capacity
        self.rsvpStatus = rsvpStatus
        self.lifecycleStatus = lifecycleStatus
        self.conversationThreadID = conversationThreadID
    }

    public var scheduleLine: String {
        if let startsAt {
            return ActivityFormatting.scheduleLine(startsAt: startsAt, locationName: locationName)
        }
        return summary
    }

    public var isAtCapacity: Bool {
        ActivityRegistrationRules.isAtCapacity(attendeeCount: attendeeCount, capacity: capacity)
    }

    public var lifecycleBadge: String? {
        switch lifecycleStatus {
        case .scheduled:
            if isAtCapacity, rsvpStatus == .invited || rsvpStatus == .waitlisted {
                return String(localized: "activity.badge.full", defaultValue: "已满", comment: "List badge")
            }
            if rsvpStatus == .waitlisted {
                return ActivityRSVPStatus.waitlisted.localizedLabel
            }
            return nil
        case .cancelled, .ended:
            return lifecycleStatus.localizedLabel
        }
    }
}
