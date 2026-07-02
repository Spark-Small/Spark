// Module: SparkActivityTests

import Foundation
import SparkActivity
import Testing

@MainActor
struct ActivityDetailViewModelTests {
    @Test func loadPopulatesDetail() async {
        let viewModel = ActivityDetailViewModel(activityID: "act_2", repository: MockActivityFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.activity?.title.isEmpty == false)
        #expect(viewModel.activity?.locationName.isEmpty == false)
    }

    @Test func discoverEntryNormalizesCatalogRSVPToInvited() async {
        let viewModel = ActivityDetailViewModel(
            activityID: "act_1",
            repository: MockActivityFeedRepository(),
            context: .discover
        )
        await viewModel.load()
        #expect(viewModel.activity?.rsvpStatus == .invited)
    }

    @Test func submitRSVPUpdatesStatusWithMaybeWhenFull() async {
        let repository = MockActivityFeedRepository()
        let viewModel = ActivityDetailViewModel(activityID: "act_2", repository: repository)
        await viewModel.load()
        await viewModel.submitRSVP(.going)
        #expect(viewModel.activity?.rsvpStatus != .going)
        #expect(viewModel.rsvpErrorMessage?.isEmpty == false)
        await viewModel.submitRSVP(.maybe)
        #expect(viewModel.activity?.rsvpStatus == .maybe)
    }

    @Test func cancelAttendanceSetsDeclined() async {
        let repository = MockActivityFeedRepository()
        let viewModel = ActivityDetailViewModel(activityID: "act_1", repository: repository)
        await viewModel.load()
        await viewModel.cancelAttendance()
        #expect(viewModel.activity?.rsvpStatus == .declined)
    }

    @Test func externalEntryRSVPPromptsInviteFriends() async {
        let viewModel = ActivityDetailViewModel(
            activityID: "act_2",
            repository: MockActivityFeedRepository(),
            context: .externalEntry
        )
        await viewModel.load()
        await viewModel.submitRSVP(.maybe)
        #expect(viewModel.shouldPromptInviteFriends == true)
    }

    @Test func inboxRSVPDoesNotPromptInviteFriends() async {
        let viewModel = ActivityDetailViewModel(
            activityID: "act_2",
            repository: MockActivityFeedRepository(),
            context: .inbox
        )
        await viewModel.load()
        await viewModel.submitRSVP(.maybe)
        #expect(viewModel.shouldPromptInviteFriends == false)
    }
}
