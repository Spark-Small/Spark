// Module: SparkActivity — Full activity invitation for detail screen.

import Foundation

public struct ActivityDetail: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: String
    public let description: String
    public let startsAt: Date
    public let endsAt: Date?
    public let recurrence: ActivityRecurrenceRule?
    public let locationName: String
    public let hostDisplayName: String
    public let hostID: String?
    public let hostBio: String?
    public let hostTier: ActivityHostTier
    public let attendeeCount: Int
    public let waitlistedCount: Int
    public let capacity: Int?
    public let rsvpStatus: ActivityRSVPStatus
    public let lifecycleStatus: ActivityLifecycleStatus
    public let attendees: [ActivityAttendee]
    public let conversationThreadID: String?

    public init(
        id: String,
        title: String,
        summary: String,
        category: String,
        description: String,
        startsAt: Date,
        endsAt: Date? = nil,
        recurrence: ActivityRecurrenceRule? = nil,
        locationName: String,
        hostDisplayName: String,
        hostID: String? = nil,
        hostBio: String? = nil,
        hostTier: ActivityHostTier = .standard,
        attendeeCount: Int,
        waitlistedCount: Int = 0,
        capacity: Int? = nil,
        rsvpStatus: ActivityRSVPStatus,
        lifecycleStatus: ActivityLifecycleStatus = .scheduled,
        attendees: [ActivityAttendee] = [],
        conversationThreadID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.category = category
        self.description = description
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.recurrence = recurrence
        self.locationName = locationName
        self.hostDisplayName = hostDisplayName
        self.hostID = hostID
        self.hostBio = hostBio
        self.hostTier = hostTier
        self.attendeeCount = attendeeCount
        self.waitlistedCount = waitlistedCount
        self.capacity = capacity
        self.rsvpStatus = rsvpStatus
        self.lifecycleStatus = lifecycleStatus
        self.attendees = attendees
        self.conversationThreadID = conversationThreadID
    }

    public var scheduleLine: String {
        ActivityFormatting.scheduleLine(startsAt: startsAt, locationName: locationName)
    }

    public var attendeeLine: String {
        ActivityFormatting.attendeeLine(attendeeCount: attendeeCount, capacity: capacity)
    }

    public var isAtCapacity: Bool {
        ActivityRegistrationRules.isAtCapacity(attendeeCount: attendeeCount, capacity: capacity)
    }

    public var canSelectGoing: Bool {
        ActivityRegistrationRules.canSelectGoing(
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus
        )
    }

    public var canChangeRSVP: Bool {
        ActivityRegistrationRules.canChangeRSVP(
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus
        )
    }

    public var registrationBlockedMessage: String? {
        ActivityRegistrationRules.registrationBlockedMessage(
            lifecycleStatus: lifecycleStatus,
            isAtCapacity: isAtCapacity,
            rsvpStatus: rsvpStatus
        )
    }

    public var showsRegistrantActions: Bool {
        rsvpStatus.hasGroupChatAccess && lifecycleStatus == .scheduled
    }

    public var showsHostManagement: Bool {
        rsvpStatus == .host && lifecycleStatus == .scheduled
    }

    public var canJoinWaitlist: Bool {
        ActivityRegistrationRules.canJoinWaitlist(
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus
        )
    }

    public var showsEndedRecap: Bool {
        lifecycleStatus == .ended && (rsvpStatus.hasGroupChatAccess || rsvpStatus == .host)
    }

    public var signupCounts: ActivitySignupCounts {
        var going = 0
        var maybe = 0
        var declined = 0
        var waitlisted = 0
        for attendee in attendees where !attendee.isHost {
            switch attendee.rsvpStatus {
            case .going:
                going += 1
            case .maybe:
                maybe += 1
            case .declined:
                declined += 1
            case .waitlisted:
                waitlisted += 1
            case .invited, .host, .none:
                break
            }
        }
        if waitlisted == 0, waitlistedCount > 0 {
            waitlisted = waitlistedCount
        }
        return ActivitySignupCounts(going: going, maybe: maybe, declined: declined, waitlisted: waitlisted)
    }

    public func updatingLifecycle(_ status: ActivityLifecycleStatus) -> ActivityDetail {
        rebuilding(lifecycleStatus: status)
    }

    public func updating(from draft: CreateActivityDraft) -> ActivityDetail {
        rebuilding(
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: ActivityFormatting.scheduleLine(
                startsAt: draft.startsAt,
                locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: draft.startsAt,
            locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            capacity: draft.capacity
        )
    }

    public func asListItem() -> ActivityItem {
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
            hostTier: hostTier,
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            conversationThreadID: conversationThreadID
        )
    }

    public func updatingRSVP(_ status: ActivityRSVPStatus) -> ActivityDetail {
        rebuilding(rsvpStatus: status)
    }

    public func updatingThreadID(_ threadID: String) -> ActivityDetail {
        rebuilding(conversationThreadID: threadID)
    }

    public func updatingWaitlistedCount(_ count: Int) -> ActivityDetail {
        rebuilding(waitlistedCount: count)
    }

    public func updatingAttendeeCount(_ count: Int) -> ActivityDetail {
        updatingAttendees(attendees, attendeeCount: count)
    }

    public func updatingAttendees(
        _ attendees: [ActivityAttendee],
        attendeeCount: Int? = nil,
        waitlistedCount: Int? = nil
    ) -> ActivityDetail {
        rebuilding(
            attendeeCount: attendeeCount ?? self.attendeeCount,
            waitlistedCount: waitlistedCount ?? self.waitlistedCount,
            attendees: attendees
        )
    }

    private func rebuilding(
        title: String? = nil,
        summary: String? = nil,
        category: String? = nil,
        description: String? = nil,
        startsAt: Date? = nil,
        endsAt: Date? = nil,
        recurrence: ActivityRecurrenceRule? = nil,
        locationName: String? = nil,
        hostDisplayName: String? = nil,
        hostID: String? = nil,
        hostBio: String? = nil,
        hostTier: ActivityHostTier? = nil,
        attendeeCount: Int? = nil,
        waitlistedCount: Int? = nil,
        capacity: Int? = nil,
        rsvpStatus: ActivityRSVPStatus? = nil,
        lifecycleStatus: ActivityLifecycleStatus? = nil,
        attendees: [ActivityAttendee]? = nil,
        conversationThreadID: String? = nil
    ) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: title ?? self.title,
            summary: summary ?? self.summary,
            category: category ?? self.category,
            description: description ?? self.description,
            startsAt: startsAt ?? self.startsAt,
            endsAt: endsAt ?? self.endsAt,
            recurrence: recurrence ?? self.recurrence,
            locationName: locationName ?? self.locationName,
            hostDisplayName: hostDisplayName ?? self.hostDisplayName,
            hostID: hostID ?? self.hostID,
            hostBio: hostBio ?? self.hostBio,
            hostTier: hostTier ?? self.hostTier,
            attendeeCount: attendeeCount ?? self.attendeeCount,
            waitlistedCount: waitlistedCount ?? self.waitlistedCount,
            capacity: capacity ?? self.capacity,
            rsvpStatus: rsvpStatus ?? self.rsvpStatus,
            lifecycleStatus: lifecycleStatus ?? self.lifecycleStatus,
            attendees: attendees ?? self.attendees,
            conversationThreadID: conversationThreadID ?? self.conversationThreadID
        )
    }
}
