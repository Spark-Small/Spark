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
}
