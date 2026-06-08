// Module: SparkActivity — Host roster mutations for mock feed.

import Foundation

enum MockActivityFeedHostActions {
    static func reviewAttendee(
        detail: ActivityDetail,
        attendeeID: String,
        decision: AttendeeReviewDecision
    ) throws -> ActivityDetail {
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        var attendees = detail.attendees
        guard let index = attendees.firstIndex(where: { attendee in
            attendee.id == attendeeID
                && (attendee.rsvpStatus == .pending || attendee.rsvpStatus == .waitlisted)
        }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        let member = attendees[index]
        switch decision {
        case .approve:
            attendees[index] = ActivityAttendee(
                id: member.id,
                displayName: member.displayName,
                isHost: false,
                rsvpStatus: .going,
                isVerified: member.isVerified,
                isCohost: member.isCohost
            )
            return detail.updatingAttendees(
                attendees,
                attendeeCount: detail.attendeeCount + 1,
                waitlistedCount: member.rsvpStatus == .waitlisted
                    ? max(0, detail.waitlistedCount - 1)
                    : detail.waitlistedCount
            )
        case .reject:
            attendees[index] = ActivityAttendee(
                id: member.id,
                displayName: member.displayName,
                isHost: false,
                rsvpStatus: .declined,
                isVerified: member.isVerified,
                isCohost: member.isCohost
            )
            return detail.updatingAttendees(
                attendees,
                attendeeCount: detail.attendeeCount,
                waitlistedCount: member.rsvpStatus == .waitlisted
                    ? max(0, detail.waitlistedCount - 1)
                    : detail.waitlistedCount
            )
        }
    }

    static func assignCohost(detail: ActivityDetail, attendeeID: String) throws -> ActivityDetail {
        guard detail.rsvpStatus == .host else {
            throw ActivityError.underlying(.server(statusCode: 403, message: nil))
        }
        var attendees = detail.attendees
        guard let index = attendees.firstIndex(where: {
            $0.id == attendeeID && $0.rsvpStatus == .going && !$0.isHost && !$0.isCohost
        }) else {
            throw ActivityError.underlying(.server(statusCode: 404, message: nil))
        }
        let member = attendees[index]
        attendees[index] = ActivityAttendee(
            id: member.id,
            displayName: member.displayName,
            isHost: false,
            rsvpStatus: .going,
            isVerified: member.isVerified,
            isCohost: true
        )
        return detail.updatingAttendees(attendees)
    }
}

private extension ActivityDetail {
    func updatingAttendees(
        _ attendees: [ActivityAttendee],
        attendeeCount: Int? = nil,
        waitlistedCount: Int? = nil
    ) -> ActivityDetail {
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
            attendeeCount: attendeeCount ?? self.attendeeCount,
            waitlistedCount: waitlistedCount ?? self.waitlistedCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus,
            attendees: attendees,
            conversationThreadID: conversationThreadID
        )
    }
}
