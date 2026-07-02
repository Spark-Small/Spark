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
    /// Meetup-style organizer group display name (optional API field).
    public let hostGroupName: String?
    /// Organizer / group rating 0–5 (optional API field).
    public let hostRating: Double?
    /// Review count for organizer group (optional API field).
    public let hostReviewCount: Int?
    /// Price label e.g. "Free" (optional API field).
    public let priceLabel: String?
    /// Host-uploaded cover image or video URL (optional until API ships).
    public let coverURL: URL?
    /// Poster frame for video covers.
    public let coverPosterURL: URL?
    public let coverIsVideo: Bool

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
        conversationThreadID: String? = nil,
        hostGroupName: String? = nil,
        hostRating: Double? = nil,
        hostReviewCount: Int? = nil,
        priceLabel: String? = nil,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool = false
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
        self.hostGroupName = hostGroupName
        self.hostRating = hostRating
        self.hostReviewCount = hostReviewCount
        self.priceLabel = priceLabel
        self.coverURL = coverURL
        self.coverPosterURL = coverPosterURL
        self.coverIsVideo = coverIsVideo
    }

    /// Resolved group title for Meetup-style host card.
    public var displayHostGroupName: String {
        if let hostGroupName, !hostGroupName.isEmpty {
            return hostGroupName
        }
        let format = String(
            localized: "activity.detail.hostGroup.fallback.format",
            defaultValue: "%@ 的活动群",
            comment: "Fallback host group name; %@ is host name"
        )
        return String(format: format, locale: .current, hostDisplayName)
    }

    /// Price line for detail meta (defaults to free when unset).
    public var displayPriceLabel: String {
        if let priceLabel, !priceLabel.isEmpty {
            return priceLabel
        }
        return String(localized: "activity.detail.price.free", defaultValue: "免费", comment: "Free event price")
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

    /// Remaining spots when capacity is set (Meetup-style "spots left").
    public var spotsRemainingLine: String? {
        guard let capacity else { return nil }
        let remaining = max(0, capacity - attendeeCount)
        guard remaining > 0, !isAtCapacity else { return nil }
        let format = String(
            localized: "activity.detail.spotsRemaining.format",
            defaultValue: "还剩 %lld 个名额",
            comment: "Spots remaining; %lld is count"
        )
        return String(format: format, locale: .current, remaining)
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
            category: draft.category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? category
                : draft.category.trimmingCharacters(in: .whitespacesAndNewlines),
            description: draft.description.trimmingCharacters(in: .whitespacesAndNewlines),
            startsAt: draft.startsAt,
            locationName: draft.locationName.trimmingCharacters(in: .whitespacesAndNewlines),
            capacity: draft.capacity,
            coverURL: draft.coverURL,
            coverPosterURL: draft.coverPosterURL,
            coverIsVideo: draft.coverIsVideo
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

    /// Public discover browse cards treat the viewer as not yet responded.
    public func asBrowseListItem() -> ActivityItem {
        asListItem().withRSVPStatus(.invited)
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
        conversationThreadID: String? = nil,
        hostGroupName: String? = nil,
        hostRating: Double? = nil,
        hostReviewCount: Int? = nil,
        priceLabel: String? = nil,
        coverURL: URL? = nil,
        coverPosterURL: URL? = nil,
        coverIsVideo: Bool? = nil
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
            conversationThreadID: conversationThreadID ?? self.conversationThreadID,
            hostGroupName: hostGroupName ?? self.hostGroupName,
            hostRating: hostRating ?? self.hostRating,
            hostReviewCount: hostReviewCount ?? self.hostReviewCount,
            priceLabel: priceLabel ?? self.priceLabel,
            coverURL: coverURL ?? self.coverURL,
            coverPosterURL: coverPosterURL ?? self.coverPosterURL,
            coverIsVideo: coverIsVideo ?? self.coverIsVideo
        )
    }
}
