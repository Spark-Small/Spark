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
    public let coverURL: URL?
    public let coverPosterURL: URL?
    public let coverIsVideo: Bool

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
        conversationThreadID: String? = nil,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool = false
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
        self.coverURL = coverURL
        self.coverPosterURL = coverPosterURL
        self.coverIsVideo = coverIsVideo
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

    /// Returns a copy with an updated viewer RSVP state.
    public func withRSVPStatus(_ rsvpStatus: ActivityRSVPStatus) -> ActivityItem {
        ActivityItem(
            id: id,
            title: title,
            summary: summary,
            category: category,
            startsAt: startsAt,
            endsAt: endsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            conversationThreadID: conversationThreadID,
            coverURL: coverURL,
            coverPosterURL: coverPosterURL,
            coverIsVideo: coverIsVideo
        )
    }

}
