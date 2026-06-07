// Module: SparkActivityTests — Mock repository integration for Data layer coverage.

@testable import SparkActivity
import Foundation
import Testing

struct ActivityMockRepositoryIntegrationTests {
    @Test func mockFeedRepositoryExercisesAllOperations() async throws {
        let repository = MockActivityFeedRepository()
        let browse = MockActivityBrowseRepository()

        let items = try await repository.fetchActivities()
        #expect(!items.isEmpty)

        _ = try await repository.fetchActivitiesByHost(hostID: "host_hike", excludingActivityID: "act_1")
        let detail = try await repository.fetchActivity(id: "act_1")
        _ = try await repository.updateRSVP(activityID: detail.id, status: .maybe)

        var draft = CreateActivityDraft()
        draft.title = "Integration"
        draft.description = "Covers mock paths"
        draft.locationName = "Shanghai"
        draft.capacity = 8
        let created = try await repository.createActivity(draft)
        draft.title = "Integration Updated"
        _ = try await repository.updateActivity(activityID: created.id, draft: draft)
        _ = try await repository.cancelActivity(activityID: created.id)

        _ = try await repository.reportActivity(activityID: "act_1", reason: .safety)
        _ = try await repository.joinWaitlist(activityID: "act_2")
        _ = try await repository.promoteFromWaitlist(activityID: "act_3", attendeeID: "member_3_排队君")
        _ = try await repository.updateRSVP(activityID: "act_1", status: .going)
        try await repository.announceActivity(activityID: "act_1", message: "Reminder")
        try await repository.submitHostFeedback(activityID: "act_1", feedback: .positive)

        let page = try await browse.fetchBrowse(query: ActivityBrowseQuery())
        #expect(!page.items.isEmpty)
    }
}

struct ActivityRegistrationRulesTests {
    @Test func goingAllowedWhenBelowCapacity() {
        let allowed = ActivityRegistrationRules.canSelectGoing(
            attendeeCount: 3,
            capacity: 8,
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        #expect(allowed)
    }

    @Test func waitlistWhenFullAndInvited() {
        let allowed = ActivityRegistrationRules.canJoinWaitlist(
            attendeeCount: 8,
            capacity: 8,
            rsvpStatus: .invited,
            lifecycleStatus: .scheduled
        )
        #expect(allowed)
    }

    @Test func endedLifecycleBlocksWaitlist() {
        let allowed = ActivityRegistrationRules.canJoinWaitlist(
            attendeeCount: 8,
            capacity: 8,
            rsvpStatus: .invited,
            lifecycleStatus: .ended
        )
        #expect(allowed == false)
    }
}

struct ActivityDomainModelTests {
    @Test func activityDetailSignupCountsDerived() async throws {
        let detail = try await MockActivityFeedRepository().fetchActivity(id: "act_1")
        #expect(detail.signupCounts.localizedSummary.isEmpty == false)
    }

    @Test func createActivityDraftValidationRejectsEmptyTitle() {
        var draft = CreateActivityDraft()
        draft.title = "   "
        #expect(draft.isValid == false)
    }

    @Test func activityLinkConfigurationHasHTTPSBase() {
        #expect(ActivityLinkConfiguration.webBaseURL.scheme == "https")
    }

    @Test func rsvpStatusMapsWireValues() {
        #expect(ActivityRSVPStatus(rawValue: "going") == .going)
        #expect(ActivityRSVPStatus(rawValue: "invalid") == nil)
    }

    @Test func activityFormattingScheduleLine() {
        let detail = ActivityDetail(
            id: "act_1",
            title: "Hike",
            summary: "Trail",
            category: "event",
            description: "Desc",
            startsAt: Date(timeIntervalSince1970: 1_718_000_000),
            locationName: "Park",
            hostDisplayName: "Alex",
            hostID: "host_1",
            hostBio: "",
            attendeeCount: 2,
            waitlistedCount: 0,
            capacity: 8,
            rsvpStatus: .going,
            lifecycleStatus: .scheduled,
            attendees: [],
            conversationThreadID: "th_activity_act_1"
        )
        #expect(
            ActivityFormatting.scheduleLine(startsAt: detail.startsAt, locationName: detail.locationName)
                .contains("Park")
        )
    }
}
