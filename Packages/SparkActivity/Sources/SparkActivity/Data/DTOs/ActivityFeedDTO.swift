// Module: SparkActivity — Activity feed API payloads.

import Foundation

struct ActivityFeedResponseDTO: Decodable, Sendable {
    let items: [ActivityItemDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

struct ActivityBrowseResponseDTO: Decodable, Sendable {
    let items: [ActivityItemDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case items
        case nextCursor = "next_cursor"
    }
}

struct ActivityRecurrenceDTO: Decodable, Sendable {
    let frequency: String?
    let weekday: String?
    let until: String?
}

struct ActivityItemDTO: Decodable, Sendable {
    let id: String
    let title: String
    let summary: String
    let category: String
    let threadId: String?
    let startsAt: String?
    let endsAt: String?
    let recurrence: ActivityRecurrenceDTO?
    let locationName: String?
    let hostDisplayName: String?
    let hostID: String?
    let hostBio: String?
    let hostTier: String?
    let attendeeCount: Int?
    let waitlistedCount: Int?
    let capacity: Int?
    let rsvpStatus: String?
    let lifecycleStatus: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case category
        case threadId = "thread_id"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case recurrence
        case locationName = "location_name"
        case hostDisplayName = "host_display_name"
        case hostID = "host_id"
        case hostBio = "host_bio"
        case hostTier = "host_tier"
        case attendeeCount = "attendee_count"
        case waitlistedCount = "waitlisted_count"
        case capacity
        case rsvpStatus = "rsvp_status"
        case lifecycleStatus = "lifecycle_status"
    }
}

struct ActivityAttendeeDTO: Decodable, Sendable {
    let id: String?
    let displayName: String
    let isHost: Bool?
    let rsvpStatus: String?
    let verified: Bool?
    let isCoHost: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case isHost = "is_host"
        case rsvpStatus = "rsvp_status"
        case verified
        case isCoHost = "is_co_host"
    }
}

struct ActivityReportResponseDTO: Decodable, Sendable {
    let reportID: String

    enum CodingKeys: String, CodingKey {
        case reportID = "report_id"
    }
}

struct ActivityReportRequestDTO: Encodable, Sendable {
    let reason: String
}

struct ActivityDetailResponseDTO: Decodable, Sendable {
    let activity: ActivityDetailDTO
}

struct ActivityDetailDTO: Decodable, Sendable {
    let id: String
    let title: String
    let summary: String
    let category: String
    let description: String
    let startsAt: String
    let endsAt: String?
    let recurrence: ActivityRecurrenceDTO?
    let locationName: String
    let hostDisplayName: String
    let hostID: String?
    let hostBio: String?
    let hostTier: String?
    let attendeeCount: Int
    let waitlistedCount: Int?
    let capacity: Int?
    let rsvpStatus: String
    let threadId: String?
    let lifecycleStatus: String?
    let attendees: [ActivityAttendeeDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case summary
        case category
        case description
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case recurrence
        case locationName = "location_name"
        case hostDisplayName = "host_display_name"
        case hostID = "host_id"
        case hostBio = "host_bio"
        case hostTier = "host_tier"
        case attendeeCount = "attendee_count"
        case waitlistedCount = "waitlisted_count"
        case capacity
        case rsvpStatus = "rsvp_status"
        case threadId = "thread_id"
        case lifecycleStatus = "lifecycle_status"
        case attendees
    }
}

struct ActivityAnnounceRequestDTO: Encodable, Sendable {
    let message: String
}

struct ActivityHostFeedbackRequestDTO: Encodable, Sendable {
    let feedback: String
}

struct ActivityRSVPRequestDTO: Encodable, Sendable {
    let status: String
}

struct ActivityAttendeeReviewRequestDTO: Encodable, Sendable {
    let approve: Bool
}

struct ActivityAttendeeCoHostRequestDTO: Encodable, Sendable {
    let isCoHost: Bool

    enum CodingKeys: String, CodingKey {
        case isCoHost = "is_co_host"
    }
}

struct ActivityRSVPResponseDTO: Decodable, Sendable {
    let activity: ActivityDetailDTO
}
