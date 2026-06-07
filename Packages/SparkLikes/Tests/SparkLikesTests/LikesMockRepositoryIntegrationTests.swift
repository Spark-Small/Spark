// Module: SparkLikesTests — Mock repository integration for Data layer coverage.

@testable import SparkLikes
import SparkCore
import Testing

struct LikesMockRepositoryIntegrationTests {
    @Test func mockFeedRepositoryExercisesAllOperations() async throws {
        let repository = MockLikesFeedRepository()

        _ = try await repository.fetchFeed(query: LikesFeedQuery(genderPreference: .opposite, intent: .friends))
        _ = try await repository.fetchInbound(cursor: nil)
        var profile = try await repository.fetchViewerProfile()
        profile.displayName = "Alex"
        profile.hasPhoto = true
        _ = try await repository.updateViewerProfile(profile)
        _ = try await repository.prepareAvatarUpload(contentType: "image/jpeg")
        _ = try await repository.fetchDailyStats()
        _ = try await repository.submitLike(SendLikeRequest(userID: UserID("u_like_3"), intensity: .like))
        try await repository.submitPass(userID: UserID("u_like_1"))
        _ = try await repository.rewindLastPass()
        _ = try await repository.submitFriendRequest(userID: UserID("u_like_4"))
        try await repository.reportUser(userID: UserID("u_like_6"), reason: "spam", detail: nil)
        try await repository.blockUser(userID: UserID("u_like_6"))
        try await repository.syncPremiumEntitlement(isActive: true)
    }
}

struct LikesDomainModelTests {
    @Test func sendLikeRequestCarriesIntensity() {
        let request = SendLikeRequest(userID: UserID("u_1"), intensity: .spark)
        #expect(request.intensity == .spark)
    }

    @Test func dailyLikeStatsDefaultsAreNonNegative() {
        let stats = DailyLikeStats(todaySeenCount: 0, dailyPoolSize: 50, sparkChargesRemaining: 3)
        #expect(stats.sparkChargesRemaining >= 0)
    }
}
