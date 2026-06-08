// Module: SparkActivityTests — DTO mapping coverage.

@testable import SparkActivity
import Foundation
import Testing

struct ActivityDTOMapperTests {
    @Test func itemMapsDefaults() throws {
        let json = """
        {
          "id": "act_1",
          "title": "Hike",
          "summary": "Saturday",
          "category": "event",
          "starts_at": "2026-06-07T10:00:00Z",
          "location_name": "Trail",
          "host_display_name": "Alex",
          "host_id": "host_1",
          "attendee_count": 3,
          "capacity": 8,
          "rsvp_status": "going",
          "lifecycle_status": "scheduled",
          "thread_id": "th_act_1"
        }
        """
        let dto = try JSONDecoder().decode(ActivityItemDTO.self, from: Data(json.utf8))
        let item = ActivityDTOMapper.item(from: dto)
        #expect(item.id == "act_1")
        #expect(item.rsvpStatus == .going)
    }

    @Test func detailMapsAttendees() throws {
        let json = """
        {
          "id": "act_2",
          "title": "Coffee",
          "summary": "Tonight",
          "category": "social",
          "description": "Chat",
          "starts_at": "2026-06-07T18:00:00Z",
          "location_name": "Cafe",
          "host_display_name": "Sam",
          "host_id": "host_2",
          "host_bio": "Host bio",
          "attendee_count": 2,
          "waitlisted_count": 1,
          "capacity": 4,
          "rsvp_status": "invited",
          "lifecycle_status": "scheduled",
          "attendees": [
            {
              "id": "att_1",
              "display_name": "Guest",
              "is_host": false,
              "rsvp_status": "going",
              "verified": true
            }
          ],
          "thread_id": "th_act_2"
        }
        """
        let dto = try JSONDecoder().decode(ActivityDetailDTO.self, from: Data(json.utf8))
        let detail = ActivityDTOMapper.detail(from: dto)
        #expect(detail?.attendees.count == 1)
        #expect(detail?.attendees.first?.isVerified == true)
    }

    @Test func detailMapsScheduleExtensions() throws {
        let json = """
        {
          "id": "act_3",
          "title": "Friday Coffee",
          "summary": "Tonight",
          "category": "social",
          "description": "Chat",
          "starts_at": "2026-06-06T19:00:00Z",
          "ends_at": "2026-06-06T21:00:00Z",
          "recurrence": {
            "frequency": "weekly",
            "weekday": "friday",
            "until": "2027-06-06T21:00:00Z"
          },
          "location_name": "Cafe",
          "host_display_name": "Sam",
          "host_tier": "super_organizer",
          "attendee_count": 2,
          "rsvp_status": "invited",
          "lifecycle_status": "scheduled"
        }
        """
        let dto = try JSONDecoder().decode(ActivityDetailDTO.self, from: Data(json.utf8))
        let detail = try #require(ActivityDTOMapper.detail(from: dto))
        #expect(detail.endsAt != nil)
        #expect(detail.recurrence?.frequency == .weekly)
        #expect(detail.recurrence?.weekday == .friday)
        #expect(detail.hostTier == .superOrganizer)
        let schedule = ActivityFormatting.detailMeetupScheduleLine(
            startsAt: detail.startsAt,
            endsAt: detail.endsAt
        )
        #expect(schedule.contains("to"))
        let recurrence = try #require(detail.recurrence)
        let recurrenceLine = ActivityFormatting.detailRecurrenceLine(recurrence)
        // REASONING: Simulator locale may be zh-Hans (星期五) or en (Friday).
        let hasFridayLabel = recurrenceLine.localizedCaseInsensitiveContains("Friday")
            || recurrenceLine.contains("星期五")
        #expect(hasFridayLabel)
    }

    @Test func detailReturnsNilForInvalidRSVP() throws {
        let json = """
        {
          "id": "act_bad",
          "title": "Bad",
          "summary": "Bad",
          "category": "event",
          "description": "Bad",
          "starts_at": "2026-06-07T10:00:00Z",
          "location_name": "X",
          "host_display_name": "X",
          "attendee_count": 0,
          "rsvp_status": "not-a-status",
          "lifecycle_status": "scheduled"
        }
        """
        let dto = try JSONDecoder().decode(ActivityDetailDTO.self, from: Data(json.utf8))
        #expect(ActivityDTOMapper.detail(from: dto) == nil)
    }
}

struct ActivityThreadIDTests {
    @Test func makeProducesStablePrefix() {
        let threadID = ActivityThreadID.make(for: "act_1")
        #expect(threadID.hasPrefix("th_activity_"))
    }

    @Test func inviteURLBuildsDeepLink() {
        let url = ActivityInviteURL.deepLink(activityID: "act_1")
        #expect(url.scheme == "spark")
    }
}
