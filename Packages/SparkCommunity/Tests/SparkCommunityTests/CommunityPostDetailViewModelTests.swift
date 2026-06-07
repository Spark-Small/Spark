// Module: SparkCommunityTests

import Foundation
import SparkCommunity
import Testing

@MainActor
struct CommunityPostDetailViewModelTests {
    @Test func loadPopulatesPost() async {
        let viewModel = CommunityPostDetailViewModel(postID: "cp_1", repository: MockCommunityPostsRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.post?.title.isEmpty == false)
    }

    @Test func loadMissingPostSetsFailure() async {
        let viewModel = CommunityPostDetailViewModel(postID: "missing", repository: MockCommunityPostsRepository())
        await viewModel.load()
        if case .failure = viewModel.loadState {
            // expected
        } else {
            Issue.record("Expected failure state")
        }
    }

    @Test func sendReplyAppendsToThread() async {
        let viewModel = CommunityPostDetailViewModel(postID: "cp_1", repository: MockCommunityPostsRepository())
        await viewModel.load()
        viewModel.replyDraft = "Smoke reply"
        await viewModel.sendReply()
        #expect(viewModel.replyState == .idle)
        #expect(viewModel.post?.replies.count == 2)
        #expect(viewModel.post?.replyCount == 2)
    }

    @Test func loadFeedOnlyPostSucceeds() async {
        let viewModel = CommunityPostDetailViewModel(
            postID: "cp_recap_mock",
            repository: MockCommunityPostsRepository()
        )
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.post?.id == "cp_recap_mock")
        #expect(viewModel.post?.mediaItems.isEmpty == false)
    }

    @Test func sendReplyIncrementsDisplayedCount() async {
        let viewModel = CommunityPostDetailViewModel(
            postID: "cp_recap_mock",
            repository: MockCommunityPostsRepository()
        )
        await viewModel.load()
        let initialCount = viewModel.post?.replyCount ?? 0
        viewModel.replyDraft = "Looks great"
        await viewModel.sendReply()
        #expect(viewModel.post?.replyCount == initialCount + 1)
        #expect(viewModel.post?.replies.count == initialCount + 1)
    }

    @Test func submitReportSetsSubmitted() async {
        let viewModel = CommunityPostDetailViewModel(postID: "cp_1", repository: MockCommunityPostsRepository())
        await viewModel.submitReport(reason: .spam, detail: nil)
        #expect(viewModel.reportState == .submitted)
    }
}
