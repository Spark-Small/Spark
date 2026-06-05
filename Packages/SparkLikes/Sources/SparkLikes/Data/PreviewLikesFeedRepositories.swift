// Module: SparkLikes — Preview/test stubs.

import Foundation
import SparkCore

struct EmptyLikesFeedRepository: LikesFeedRepository, Sendable {
    func fetchFeed(query: LikesFeedQuery) async throws -> LikesFeedPage {
        LikesFeedPage(items: [], nextCursor: nil)
    }

    func fetchInbound(cursor: String?) async throws -> LikesInboundPage {
        LikesInboundPage(items: [], nextCursor: nil)
    }

    func fetchViewerProfile() async throws -> LikesViewerProfile {
        LikesViewerProfile(displayName: "Preview", hasPhoto: true)
    }

    func updateViewerProfile(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile {
        profile
    }

    func prepareAvatarUpload(contentType: String) async throws -> AvatarUploadPrepared {
        let avatarURL = URL(string: "https://picsum.photos/seed/preview-avatar/400/400")!
        return AvatarUploadPrepared(uploadURL: nil, avatarURL: avatarURL)
    }

    func rewindLastPass() async throws -> DiscoverCard? {
        nil
    }

    func submitLike(_ request: SendLikeRequest) async throws -> LikeActionResult {
        LikeActionResult(outcome: .pending)
    }

    func fetchDailyStats() async throws -> DailyLikeStats {
        DailyLikeStats(todaySeenCount: 0, dailyPoolSize: 50, sparkChargesRemaining: 3)
    }

    func submitPass(userID: UserID) async throws {}

    func submitFriendRequest(userID: UserID) async throws -> LikeActionResult {
        LikeActionResult(outcome: .sent)
    }

    func reportUser(userID: UserID, reason: String, detail: String?) async throws {}

    func blockUser(userID: UserID) async throws {}

    func syncPremiumEntitlement(isActive: Bool) async throws {}
}
