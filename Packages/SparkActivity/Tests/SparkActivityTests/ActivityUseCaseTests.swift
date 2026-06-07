// Module: SparkActivityTests — Activity use case coverage.

@testable import SparkActivity
import Testing

struct ActivityUseCaseTests {
    @Test func fetchActivityFeedUseCaseReturnsSeedItems() async throws {
        let useCase = FetchActivityFeedUseCase(repository: MockActivityFeedRepository())
        let items = try await useCase()
        #expect(!items.isEmpty)
    }

    @Test func fetchActivityBrowsePageUseCaseReturnsItems() async throws {
        let useCase = FetchActivityBrowsePageUseCase(repository: MockActivityBrowseRepository())
        let page = try await useCase(query: ActivityBrowseQuery())
        #expect(page.items.count >= 2)
    }

    @Test func fetchActivityDetailUseCaseReturnsDetail() async throws {
        let useCase = FetchActivityDetailUseCase(repository: MockActivityFeedRepository())
        let detail = try await useCase(activityID: "act_1")
        #expect(detail.id == "act_1")
    }

    @Test func createActivityUseCaseCreatesItem() async throws {
        let repository = MockActivityFeedRepository()
        let useCase = CreateActivityUseCase(repository: repository)
        var draft = CreateActivityDraft()
        draft.title = "Test"
        draft.description = "Summary"
        draft.locationName = "Shanghai"
        draft.capacity = 4
        let detail = try await useCase(draft: draft)
        #expect(detail.title == "Test")
    }

    @Test func updateActivityRSVPUseCaseUpdatesStatus() async throws {
        let useCase = UpdateActivityRSVPUseCase(repository: MockActivityFeedRepository())
        let detail = try await useCase(activityID: "act_1", status: .maybe)
        #expect(detail.rsvpStatus == .maybe)
    }

    @Test func fetchActivitiesByHostUseCaseExcludesCurrentActivity() async throws {
        let useCase = FetchActivitiesByHostUseCase(repository: MockActivityFeedRepository())
        let items = try await useCase(hostID: "host_hike", excludingActivityID: "act_1")
        #expect(items.allSatisfy { $0.id != "act_1" })
    }

    @Test func cancelActivityUseCaseMarksCancelled() async throws {
        let repository = MockActivityFeedRepository()
        var draft = CreateActivityDraft()
        draft.title = "Cancel Me"
        draft.description = "Body"
        draft.locationName = "Park"
        draft.capacity = 6
        let created = try await CreateActivityUseCase(repository: repository)(draft: draft)
        let detail = try await CancelActivityUseCase(repository: repository)(activityID: created.id)
        #expect(detail.lifecycleStatus == .cancelled)
    }

    @Test func updateActivityUseCaseEditsHostActivity() async throws {
        let repository = MockActivityFeedRepository()
        let create = CreateActivityUseCase(repository: repository)
        var draft = CreateActivityDraft()
        draft.title = "Original"
        draft.description = "Body"
        draft.locationName = "Park"
        draft.capacity = 6
        let created = try await create(draft: draft)
        draft.title = "Updated"
        let updated = try await UpdateActivityUseCase(repository: repository)(activityID: created.id, draft: draft)
        #expect(updated.title == "Updated")
    }

    @Test func joinActivityWaitlistUseCaseEnqueuesUser() async throws {
        let useCase = JoinActivityWaitlistUseCase(repository: MockActivityFeedRepository())
        let detail = try await useCase(activityID: "act_2")
        #expect(detail.rsvpStatus == .waitlisted)
    }

    @Test func reportActivityUseCaseCompletes() async throws {
        let useCase = ReportActivityUseCase(repository: MockActivityFeedRepository())
        let result = try await useCase(activityID: "act_1", reason: .spam)
        #expect(result.reportID.isEmpty == false)
    }

    @Test func submitHostFeedbackUseCaseCompletes() async throws {
        let useCase = SubmitHostFeedbackUseCase(repository: MockActivityFeedRepository())
        try await useCase(activityID: "act_1", feedback: .positive)
    }

    @Test func announceActivityUseCasePostsMessage() async throws {
        let useCase = AnnounceActivityUseCase(repository: MockActivityFeedRepository())
        try await useCase(activityID: "act_1", message: "See you there")
    }

    @Test func announceActivityUseCaseEmptyMessageThrows() async {
        let useCase = AnnounceActivityUseCase(repository: MockActivityFeedRepository())
        await #expect(throws: ActivityError.emptyInput) {
            try await useCase(activityID: "act_1", message: "   ")
        }
    }

    @Test func promoteFromWaitlistUseCaseRequiresHostRole() async {
        let useCase = PromoteFromWaitlistUseCase(repository: MockActivityFeedRepository())
        await #expect(throws: (any Error).self) {
            try await useCase(activityID: "act_1", attendeeID: "guest_1")
        }
    }
}
