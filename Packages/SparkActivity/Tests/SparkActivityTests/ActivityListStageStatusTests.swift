import Testing
@testable import SparkActivity

@Suite struct ActivityListStageStatusTests {
    @Test func scheduledInvitedWithCapacityShowsRegistrationOpen() {
        let item = sampleItem(rsvpStatus: .invited, attendeeCount: 2, capacity: 8)
        #expect(item.listStageStatus == .registrationOpen)
        #expect(item.listStageStatus?.label == "报名中")
    }

    @Test func scheduledAtCapacityShowsFull() {
        let item = sampleItem(rsvpStatus: .invited, attendeeCount: 8, capacity: 8)
        #expect(item.listStageStatus == .full)
    }

    @Test func lifecycleEndedOverridesRegistration() {
        let item = sampleItem(rsvpStatus: .invited, lifecycleStatus: .ended)
        #expect(item.listStageStatus == .lifecycle(.ended))
    }

    @Test func goingShowsRSVPBadge() {
        let item = sampleItem(rsvpStatus: .going)
        #expect(item.listStageStatus == .rsvp(.going))
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
            summary: "",
            category: "社交",
            attendeeCount: attendeeCount,
            capacity: capacity,
            rsvpStatus: rsvpStatus,
            lifecycleStatus: lifecycleStatus
        )
    }
}
