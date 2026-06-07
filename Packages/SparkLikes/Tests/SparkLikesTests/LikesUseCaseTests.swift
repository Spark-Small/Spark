// Module: SparkLikesTests — Likes use case coverage.

@testable import SparkLikes
import SparkCore
import Testing

struct LikesUseCaseTests {
    @Test func fetchLikesFeedUseCaseReturnsCards() async throws {
        let useCase = FetchLikesFeedUseCase(repository: MockLikesFeedRepository())
        let page = try await useCase(query: LikesFeedQuery())
        #expect(page.items.count == 2)
    }

    @Test func submitLikeUseCaseReturnsOutcome() async throws {
        let useCase = SubmitLikeUseCase(repository: MockLikesFeedRepository())
        let outcome = try await useCase(SendLikeRequest(userID: UserID("u_like_2"), intensity: .like))
        #expect(outcome.outcome == .matched || outcome.outcome == .pending)
    }

    @Test func submitPassUseCaseRemovesCardFromFeed() async throws {
        let repository = MockLikesFeedRepository()
        let pass = SubmitPassUseCase(repository: repository)
        try await pass(userID: UserID("u_like_1"))
        let page = try await FetchLikesFeedUseCase(repository: repository)(query: LikesFeedQuery())
        #expect(page.items.contains { $0.userID.rawValue == "u_like_1" } == false)
    }

    @Test func fetchInboundLikesUseCaseReturnsItems() async throws {
        let useCase = FetchInboundLikesUseCase(repository: MockLikesFeedRepository())
        let page = try await useCase(cursor: nil)
        #expect(!page.items.isEmpty)
    }

    @Test func fetchDailyLikeStatsUseCaseReturnsPoolSize() async throws {
        let useCase = FetchDailyLikeStatsUseCase(repository: MockLikesFeedRepository())
        let stats = try await useCase()
        #expect(stats.dailyPoolSize == 50)
    }

    @Test func fetchViewerProfileUseCaseReturnsProfile() async throws {
        let useCase = FetchViewerProfileUseCase(repository: MockLikesFeedRepository())
        _ = try await useCase()
    }

    @Test func updateViewerProfileUseCasePersistsProfile() async throws {
        let repository = MockLikesFeedRepository()
        var profile = try await FetchViewerProfileUseCase(repository: repository)()
        profile.displayName = "Preview User"
        profile.hasPhoto = true
        let updated = try await UpdateViewerProfileUseCase(repository: repository)(profile)
        #expect(updated.displayName == "Preview User")
    }

    @Test func submitFriendRequestUseCaseReturnsResult() async throws {
        let useCase = SubmitFriendRequestUseCase(repository: MockLikesFeedRepository())
        let result = try await useCase(userID: UserID("u_like_2"))
        #expect(result.outcome == .sent)
    }

    @Test func rewindPassUseCaseRestoresLastCard() async throws {
        let repository = MockLikesFeedRepository()
        try await SubmitPassUseCase(repository: repository)(userID: UserID("u_like_1"))
        let card = try await RewindPassUseCase(repository: repository)()
        #expect(card?.userID.rawValue == "u_like_1")
    }

    @Test func requestAvatarUploadUseCaseReturnsUploadURL() async throws {
        let useCase = RequestAvatarUploadUseCase(repository: MockLikesFeedRepository())
        let upload = try await useCase(contentType: "image/jpeg")
        #expect(upload.avatarURL.absoluteString.isEmpty == false)
    }

    @Test func reportAndBlockUserUseCaseBlocksUser() async throws {
        let repository = MockLikesFeedRepository()
        try await ReportUserUseCase(repository: repository)(
            userID: UserID("u_like_2"),
            reason: "spam",
            detail: nil
        )
        try await BlockUserUseCase(repository: repository)(userID: UserID("u_like_2"))
        let page = try await FetchLikesFeedUseCase(repository: repository)(query: LikesFeedQuery())
        #expect(page.items.contains { $0.userID.rawValue == "u_like_2" } == false)
    }

    @Test func syncPremiumEntitlementUseCaseCallsRepository() async throws {
        let repository = MockLikesFeedRepository()
        try await SyncPremiumEntitlementUseCase(repository: repository)(isActive: true)
        try await SyncPremiumEntitlementUseCase(repository: repository)(isActive: false)
    }
}
