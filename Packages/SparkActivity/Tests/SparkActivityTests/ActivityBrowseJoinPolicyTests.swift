import Foundation
import Testing
@testable import SparkActivity

@Suite struct ActivityBrowseJoinPolicyTests {
    @Test func invitedScheduledWithCapacityShowsJoin() {
        let item = sampleItem(rsvpStatus: .invited, attendeeCount: 2, capacity: 8)
        #expect(ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    @Test func fullActivityHidesJoin() {
        let item = sampleItem(rsvpStatus: .invited, attendeeCount: 8, capacity: 8)
        #expect(!ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    @Test func goingHidesJoin() {
        let item = sampleItem(rsvpStatus: .going)
        #expect(!ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    @Test func endedLifecycleHidesJoin() {
        let item = sampleItem(rsvpStatus: .invited, lifecycleStatus: .ended)
        #expect(!ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    @Test func declinedWithCapacityShowsJoin() {
        let item = sampleItem(rsvpStatus: .declined, attendeeCount: 2, capacity: 8)
        #expect(ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    @Test func waitlistedHidesJoin() {
        let item = sampleItem(rsvpStatus: .waitlisted)
        #expect(!ActivityBrowseJoinPolicy.showsJoinButton(for: item))
    }

    private func sampleItem(
        rsvpStatus: ActivityRSVPStatus,
        lifecycleStatus: ActivityLifecycleStatus = .scheduled,
        attendeeCount: Int = 2,
        capacity: Int? = 8
    ) -> ActivityItem {
        ActivityItem(
            id: "act_test",
            title: "Test",
            summary: "Bring water.",
            category: "户外",
            startsAt: Date(timeIntervalSince1970: 1_700_000_000),
            locationName: "静安公园",
            hostDisplayName: "阿乐",
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus
        )
    }
}

@Suite struct ActivityBrowseJoinSummaryTests {
    @Test func buildsScheduleHostAndTeaserLines() {
        let item = ActivityItem(
            id: "act_test",
            title: "周末徒步",
            summary: "Bring water.",
            category: "户外",
            startsAt: Date(timeIntervalSince1970: 1_700_000_000),
            endsAt: Date(timeIntervalSince1970: 1_700_003_600),
            locationName: "静安公园",
            hostDisplayName: "阿乐",
            attendeeCount: 3,
            capacity: 8,
            rsvpStatus: .invited
        )

        let summary = ActivityBrowseJoinSummary(item: item)
        #expect(summary.title == "周末徒步")
        #expect(summary.category == "户外")
        #expect(summary.scheduleLine != nil)
        #expect(summary.locationLine == "静安公园")
        #expect(summary.hostLine?.contains("阿乐") == true)
        #expect(summary.teaserLine == "Bring water.")
    }

    @Test func suppressesScheduleDuplicateTeaser() {
        let startsAt = Date(timeIntervalSince1970: 1_700_000_000)
        let item = ActivityItem(
            id: "act_test",
            title: "Walk",
            summary: ActivityFormatting.scheduleLine(startsAt: startsAt, locationName: "Park"),
            category: "户外",
            startsAt: startsAt,
            locationName: "Park",
            hostDisplayName: "Host",
            attendeeCount: 1,
            rsvpStatus: .invited
        )
        let summary = ActivityBrowseJoinSummary(item: item)
        #expect(summary.teaserLine == nil)
    }
}
