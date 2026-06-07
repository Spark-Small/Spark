// Module: SparkCommunityTests — Recap publish and feed filters.

import Foundation
import SparkCommunity
import Testing

@MainActor
struct CommunityRecapTests {
    @Test func publishRecapInsertsAtTop() async throws {
        let repository = MockCommunityPostsRepository()
        await repository.resetUserCreatedPosts()
        let viewModel = CommunityViewModel(repository: repository)
        await viewModel.load()
        let initialCount = viewModel.posts.count

        let detail = try await viewModel.publishRecap(
            CommunityRecapDraft(
                activityID: "act_browse_2",
                activityTitle: "玉林咖啡聊天局",
                scheduleLine: "周六 · 玉林西路",
                body: "氛围很好，认识了几位新朋友。"
            )
        )

        #expect(viewModel.posts.count == initialCount + 1)
        #expect(viewModel.posts.first?.id == detail.id)
        #expect(viewModel.posts.first?.kind == .activityRecap)
        #expect(detail.linkedActivity?.id == "act_browse_2")
    }

    @Test func recapFilterShowsOnlyRecapPosts() async {
        let repository = MockCommunityPostsRepository()
        await repository.resetUserCreatedPosts()
        let viewModel = CommunityViewModel(repository: repository)
        await viewModel.load()
        await viewModel.applyFilter(.recaps)
        #expect(viewModel.filteredPosts.allSatisfy { $0.kind == .activityRecap })
        #expect(viewModel.filteredPosts.count == 1)
    }

    @Test func emptyRecapBodyThrows() async {
        let repository = MockCommunityPostsRepository()
        await #expect(throws: CommunityError.self) {
            _ = try await repository.createRecapPost(
                CommunityRecapDraft(
                    activityID: "act_1",
                    activityTitle: "Test",
                    scheduleLine: "Mon",
                    body: "   "
                )
            )
        }
    }
}
