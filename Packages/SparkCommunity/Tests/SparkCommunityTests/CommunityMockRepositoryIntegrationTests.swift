// Module: SparkCommunityTests — Mock repository integration for Data layer coverage.

@testable import SparkCommunity
import Testing

struct CommunityMockRepositoryIntegrationTests {
    @Test func mockRepositoryExercisesAllOperations() async throws {
        let repository = MockCommunityPostsRepository()

        _ = try await repository.fetchPosts()
        _ = try await repository.fetchPost(id: "cp_1")
        _ = try await repository.fetchTabExperience()
        _ = try await repository.fetchCommunityDetail(id: "cm_hike")
        _ = try await repository.fetchCommunityActivities(communityID: "cm_hike")
        _ = try await repository.fetchCommunityMembers(communityID: "cm_hike")
        _ = try await repository.fetchCommunityPosts(communityID: "cm_hike")

        _ = try await repository.createPost(CreateCommunityPostDraft(title: "Hi", body: "Body"))
        _ = try await repository.createReply(postID: "cp_1", body: "Reply")
        _ = try await repository.createRecapPost(
            CommunityRecapDraft(
                activityID: "act_1",
                activityTitle: "Hike",
                scheduleLine: "Saturday",
                body: "Fun recap"
            )
        )
    }
}

struct CommunityDomainModelTests {
    @Test func createCommunityPostDraftRequiresTitle() {
        let draft = CreateCommunityPostDraft(title: " ", body: "Body")
        #expect(draft.isValid == false)
    }

    @Test func communityRecapDraftNormalizesBody() throws {
        let draft = CommunityRecapDraft(
            activityID: "act_1",
            activityTitle: "Coffee",
            scheduleLine: "Tonight",
            body: "  Great meetup  "
        )
        try CommunityRecapDraft.validate(draft)
        #expect(draft.normalizedBody == "Great meetup")
    }
}
