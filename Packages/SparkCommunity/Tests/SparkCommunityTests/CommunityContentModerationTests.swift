// Module: SparkCommunityTests — UGC moderation guard.

import Testing
@testable import SparkCommunity

struct CommunityContentModerationTests {
    @Test func rejectsBlockedPostDraft() {
        let draft = CreateCommunityPostDraft(title: "测试", body: "加微信私聊")
        #expect(throws: CommunityError.contentRejected) {
            try CommunityContentModeration.validatePostDraft(draft)
        }
    }

    @Test func createPostUseCaseRejectsBlockedContent() async {
        let repository = MockCommunityPostsRepository()
        let useCase = CreateCommunityPostUseCase(repository: repository)
        let draft = CreateCommunityPostDraft(title: "标题", body: "色情内容")
        await #expect(throws: CommunityError.contentRejected) {
            try await useCase(draft)
        }
    }
}
