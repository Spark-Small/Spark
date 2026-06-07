// Module: SparkCommunityTests — Activity share publish from ended activities.

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

    @Test func publishShareWithPhotoInsertsImageIntoFeed() async throws {
        let repository = MockCommunityPostsRepository()
        await repository.resetUserCreatedPosts()
        let viewModel = CommunityViewModel(repository: repository)
        await viewModel.load()
        let cover = URL(string: "https://picsum.photos/seed/test/800/450")

        _ = try await viewModel.publishRecap(
            CommunityRecapDraft(
                activityID: "act_browse_2",
                activityTitle: "玉林咖啡聊天局",
                scheduleLine: "周六 · 玉林西路",
                body: "氛围很好，认识了几位新朋友。",
                coverImageURL: cover,
                includesCoverImage: true
            )
        )

        guard case .post(let feedPost) = viewModel.feedItems.first else {
            Issue.record("Expected share feed post")
            return
        }
        #expect(feedPost.imageURL == cover)
        #expect(feedPost.galleryMedia.count == 1)
    }

    @Test func publishShareInsertsIntoFeed() async throws {
        let repository = MockCommunityPostsRepository()
        await repository.resetUserCreatedPosts()
        let viewModel = CommunityViewModel(repository: repository)
        await viewModel.load()
        let initialFeedCount = viewModel.feedItems.count

        _ = try await viewModel.publishRecap(
            CommunityRecapDraft(
                activityID: "act_browse_2",
                activityTitle: "玉林咖啡聊天局",
                scheduleLine: "周六 · 玉林西路",
                body: "氛围很好，认识了几位新朋友。"
            )
        )

        #expect(viewModel.feedItems.count == initialFeedCount + 1)
        guard case .post(let feedPost) = viewModel.feedItems.first else {
            Issue.record("Expected recap feed post")
            return
        }
        #expect(feedPost.kind == .activityRecap)
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
