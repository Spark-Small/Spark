// Module: SparkActivity — Wire DTO to domain models.

import Foundation

enum ActivityDTOMapper {
    static func item(from dto: ActivityItemDTO) -> ActivityItem {
        let startsAt = dto.startsAt.flatMap(ActivityFormatting.date(from:))
        let endsAt = dto.endsAt.flatMap(ActivityFormatting.date(from:))
        let rsvp = dto.rsvpStatus.flatMap(ActivityRSVPStatus.init(wireValue:)) ?? .invited
        let lifecycle = dto.lifecycleStatus.flatMap(ActivityLifecycleStatus.init(wireValue:)) ?? .scheduled
        return ActivityItem(
            id: dto.id,
            title: dto.title,
            summary: dto.summary,
            category: dto.category,
            startsAt: startsAt,
            endsAt: endsAt,
            locationName: dto.locationName ?? "",
            hostDisplayName: dto.hostDisplayName ?? "",
            hostID: dto.hostID,
            attendeeCount: dto.attendeeCount ?? 0,
            capacity: dto.capacity,
            rsvpStatus: rsvp,
            lifecycleStatus: lifecycle,
            conversationThreadID: dto.threadId
        )
    }

    static func detail(from dto: ActivityDetailDTO) -> ActivityDetail? {
        guard let startsAt = ActivityFormatting.date(from: dto.startsAt),
              let rsvp = ActivityRSVPStatus(wireValue: dto.rsvpStatus) else {
            return nil
        }
        let lifecycle = dto.lifecycleStatus.flatMap(ActivityLifecycleStatus.init(wireValue:)) ?? .scheduled
        let endsAt = dto.endsAt.flatMap(ActivityFormatting.date(from:))
        let recurrence = recurrence(from: dto.recurrence)
        return ActivityDetail(
            id: dto.id,
            title: dto.title,
            summary: dto.summary,
            category: dto.category,
            description: dto.description,
            startsAt: startsAt,
            endsAt: endsAt,
            recurrence: recurrence,
            locationName: dto.locationName,
            hostDisplayName: dto.hostDisplayName,
            hostID: dto.hostID,
            hostBio: dto.hostBio,
            hostTier: ActivityHostTier(wireValue: dto.hostTier),
            attendeeCount: dto.attendeeCount,
            waitlistedCount: dto.waitlistedCount ?? 0,
            capacity: dto.capacity,
            rsvpStatus: rsvp,
            lifecycleStatus: lifecycle,
            attendees: (dto.attendees ?? []).map(attendee(from:)),
            conversationThreadID: dto.threadId,
            hostGroupName: dto.hostGroupName,
            hostRating: dto.hostRating,
            hostReviewCount: dto.hostReviewCount,
            priceLabel: dto.priceLabel
        )
    }

    private static func recurrence(from dto: ActivityRecurrenceDTO?) -> ActivityRecurrenceRule? {
        guard let dto else { return nil }
        let until = dto.until.flatMap(ActivityFormatting.date(from:))
        return ActivityRecurrenceRule(
            wireFrequency: dto.frequency,
            wireWeekday: dto.weekday,
            until: until
        )
    }

    private static func attendee(from dto: ActivityAttendeeDTO) -> ActivityAttendee {
        let name = dto.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let id = dto.id?.trimmingCharacters(in: .whitespacesAndNewlines)
        let stableID: String
        if let id, !id.isEmpty {
            stableID = id
        } else {
            stableID = "attendee_\(name.hashValue)"
        }
        let rsvp = dto.rsvpStatus.flatMap(ActivityRSVPStatus.init(wireValue:))
        return ActivityAttendee(
            id: stableID,
            displayName: name,
            isHost: dto.isHost ?? false,
            rsvpStatus: rsvp,
            isVerified: dto.verified ?? false,
            isCoHost: dto.isCoHost ?? false
        )
    }
}
