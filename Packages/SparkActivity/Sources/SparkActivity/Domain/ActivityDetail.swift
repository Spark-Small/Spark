// Module: SparkActivity — Full activity invitation for detail screen.

import Foundation

public struct ActivityDetail: Identifiable, Hashable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let summary: String
    public let category: String
    public let description: String
    public let startsAt: Date
    public let locationName: String
    public let hostDisplayName: String
    public let hostID: String?
    public let hostBio: String?
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
        locationName: String,
        hostDisplayName: String,
        hostID: String? = nil,
        hostBio: String? = nil,
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
        self.locationName = locationName
        self.hostDisplayName = hostDisplayName
        self.hostID = hostID
        self.hostBio = hostBio
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
            case .pending:
                break
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
        ActivityDetail(
            id: id,
            title: title,
            summary: summary,
            category: category,
            description: description,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: attendeeCount,
            waitlistedCount: waitlistedCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: status,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }

    public func updating(from draft: CreateActivityDraft) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: draft.title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: ActivityFormatting.scheduleLine(
                startsAt: draft.startsAt,
                locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines)
            ),
            category: category,
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: draft.startsAt,
            locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: attendeeCount,
            waitlistedCount: waitlistedCount,
            capacity: draft.capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }

    public func asListItem() -> ActivityItem {
        ActivityItem(
            id: id,
            title: title,
            summary: summary,
            category: category,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            conversationThreadID: conversationThreadID
        )
    }

    public func updatingRSVP(_ status: ActivityRSVPStatus) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: title,
            summary: summary,
            category: category,
            description: description,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: attendeeCount,
            waitlistedCount: waitlistedCount,
            capacity: capacity,
            rsvpStatus: status,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }

    public func updatingThreadID(_ threadID: String) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: title,
            summary: summary,
            category: category,
            description: description,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: attendeeCount,
            waitlistedCount: waitlistedCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: threadID
        )
    }

    public func updatingWaitlistedCount(_ count: Int) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: title,
            summary: summary,
            category: category,
            description: description,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: attendeeCount,
            waitlistedCount: count,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }

    public func updatingAttendeeCount(_ count: Int) -> ActivityDetail {
        ActivityDetail(
            id: id,
            title: title,
            summary: summary,
            category: category,
            description: description,
            startsAt: startsAt,
            locationName: locationName,
            hostDisplayName: hostDisplayName,
            hostID: hostID,
            hostBio: hostBio,
            attendeeCount: count,
            waitlistedCount: waitlistedCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }
}
