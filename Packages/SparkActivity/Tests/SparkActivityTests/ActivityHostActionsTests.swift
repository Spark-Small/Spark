// Module: SparkActivityTests

import SparkActivity
import Testing

@MainActor
struct ActivityHostActionsTests {
    @Test func hostCanCancelActivity() async throws {
        let repository = MockActivityFeedRepository()
        let viewModel = ActivityDetailViewModel(activityID: "act_3", repository: repository)
        await viewModel.load()
        await viewModel.cancelActivityAsHost()
        #expect(viewModel.activity?.lifecycleStatus == .cancelled)
    }

    @Test func hostSignupCountsFromRoster() async throws {
        let repository = MockActivityFeedRepository()
        let detail = try await repository.fetchActivity(id: "act_3")
        #expect(detail.signupCounts.going == 1)
        #expect(detail.signupCounts.maybe == 1)
        #expect(detail.signupCounts.declined == 1)
        #expect(detail.signupCounts.waitlisted == 1)
    }

    @Test func reportActivitySucceedsForRegistrant() async throws {
        let repository = MockActivityFeedRepository()
        let result = try await repository.reportActivity(activityID: "act_2", reason: .safety)
        #expect(!result.reportID.isEmpty)
    }
}
