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
}
