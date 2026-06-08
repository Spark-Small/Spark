// Module: SparkLikesTests

@testable import SparkLikes
import Foundation
import SparkCore
import Testing

@MainActor
struct LikesFeedViewModelTests {
    private func completeViewerProfile(_ viewModel: LikesFeedViewModel) async {
        _ = await viewModel.saveViewerProfile(LikesViewerProfile(displayName: "Tester", hasPhoto: true))
    }

    @Test func loadPopulatesCards() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .loaded)
        #expect(viewModel.cards.count == 2)
        #expect(viewModel.nextCursor != nil)
    }

    @Test func loadFailureSurfacesRecovery() async {
        let viewModel = LikesFeedViewModel(repository: FailingLikesFeedRepository())
        await viewModel.load()
        guard case .failure(let error) = viewModel.loadState else {
            Issue.record("Expected failure state")
            return
        }
        #expect(error.recoverySuggestion != nil)
    }

    @Test func loadMoreAppendsCards() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        await viewModel.loadMoreIfNeeded(currentCardID: viewModel.cards.last?.id)
        #expect(viewModel.cards.count == 4)
        #expect(viewModel.nextCursor == nil)
    }

    @Test func likeMutualMatchSetsPendingMatch() async {
        let repository = MockLikesFeedRepository()
        let viewModel = LikesFeedViewModel(repository: repository)
        await viewModel.load()
        await completeViewerProfile(viewModel)
        viewModel.currentIndex = 1
        let countBefore = viewModel.cards.count
        await viewModel.likeCurrentCard()
        #expect(viewModel.pendingMatch?.outcome == .matched)
        #expect(viewModel.pendingMatch?.threadID == "th_dm_u_like_2")
        #expect(viewModel.cards.count == countBefore)
    }

    @Test func inboundLoadsFirstPageOnly() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        #expect(viewModel.inboundCount == 1)
        #expect(viewModel.inboundNextCursor != nil)
    }

    @Test func loadMoreInboundAppendsItems() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        await viewModel.loadMoreInboundIfNeeded(currentItemID: viewModel.inboundItems.last?.id)
        #expect(viewModel.inboundCount == 2)
        #expect(viewModel.inboundNextCursor == nil)
    }

    @Test func icebreakersGeneratedForMatchCard() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        viewModel.pendingMatchCard = viewModel.cards.first
        #expect(!viewModel.icebreakersForPendingMatch.isEmpty)
    }

    @Test func passAdvancesQueue() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        let firstID = viewModel.cards.first?.id
        await viewModel.passCurrentCard()
        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.cards.first?.id != firstID)
    }

    @Test func loadEmptySetsEmptyState() async {
        let viewModel = LikesFeedViewModel(repository: EmptyLikesFeedRepository())
        await viewModel.load()
        #expect(viewModel.loadState == .empty)
    }

    @Test func rewindRestoresPassedCard() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        let firstID = viewModel.cards.first?.id
        await viewModel.passCurrentCard()
        await viewModel.rewindLastPass()
        #expect(viewModel.cards.contains { $0.id == firstID })
    }

    @Test func saveViewerProfileUpdatesGate() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        let saved = await viewModel.saveViewerProfile(LikesViewerProfile(displayName: "测试", hasPhoto: true))
        #expect(saved)
        #expect(viewModel.viewerProfile.isComplete)
        #expect(!viewModel.showProfileGate)
    }

    @Test func saveViewerProfileFailureSetsGateError() async {
        let viewModel = LikesFeedViewModel(repository: FailingLikesFeedRepository())
        let saved = await viewModel.saveViewerProfile(LikesViewerProfile(displayName: "测试", hasPhoto: true))
        #expect(!saved)
        #expect(viewModel.profileGateSaveError != nil)
    }

    @Test func inboundLikeBackSetsPendingMatch() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        await completeViewerProfile(viewModel)
        guard let inboundItem = viewModel.inboundItems.first else {
            Issue.record("Expected inbound item")
            return
        }
        await viewModel.likeInboundUser(inboundItem.userID)
        #expect(viewModel.pendingMatch?.outcome == .matched)
        #expect(viewModel.pendingMatchPeerName == inboundItem.card.displayName)
        #expect(viewModel.inboundItems.isEmpty)
    }

    @Test func friendRequestAdvancesQueue() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        await completeViewerProfile(viewModel)
        let countBefore = viewModel.cards.count
        await viewModel.friendRequestCurrentCard()
        #expect(viewModel.cards.count == countBefore - 1)
    }

    @Test func reportAndBlockAdvancesQueue() async {
        let viewModel = LikesFeedViewModel(repository: MockLikesFeedRepository())
        await viewModel.load()
        let countBefore = viewModel.cards.count
        await viewModel.reportAndBlockCurrentCard(reason: .spam, detail: nil)
        #expect(viewModel.cards.count == countBefore - 1)
    }
}

struct MockLikesFeedRepositoryMatchTests {
    @Test func mutualMatchUserID() {
        #expect(MockLikesCatalog.mutualMatchUserID == UserID("u_like_2"))
    }
}

private struct FailingLikesFeedRepository: LikesFeedRepository, Sendable {
    func fetchFeed(query: LikesFeedQuery) async throws -> LikesFeedPage {
        throw LikesError.underlying(.networkUnavailable)
    }

    func fetchInbound(cursor: String?) async throws -> LikesInboundPage {
        throw LikesError.underlying(.networkUnavailable)
    }

    func fetchViewerProfile() async throws -> LikesViewerProfile {
        throw LikesError.underlying(.networkUnavailable)
    }

    func updateViewerProfile(_ profile: LikesViewerProfile) async throws -> LikesViewerProfile {
        throw LikesError.underlying(.networkUnavailable)
    }

    func rewindLastPass() async throws -> DiscoverCard? {
        throw LikesError.underlying(.networkUnavailable)
    }

    func submitLike(_ request: SendLikeRequest) async throws -> LikeActionResult {
        throw LikesError.underlying(.networkUnavailable)
    }

    func fetchDailyStats() async throws -> DailyLikeStats {
        throw LikesError.underlying(.networkUnavailable)
    }

    func submitPass(userID: UserID) async throws {
        throw LikesError.underlying(.networkUnavailable)
    }

    func submitFriendRequest(userID: UserID) async throws -> LikeActionResult {
        throw LikesError.underlying(.networkUnavailable)
    }

    func reportUser(userID: UserID, reason: String, detail: String?) async throws {
        throw LikesError.underlying(.networkUnavailable)
    }

    func blockUser(userID: UserID) async throws {
        throw LikesError.underlying(.networkUnavailable)
    }

    func syncPremiumEntitlement(isActive: Bool) async throws {
        throw LikesError.underlying(.networkUnavailable)
    }
}

struct MockLikesInboundPremiumTests {
    @Test func inboundVisibilityFollowsPremiumSync() async throws {
        let repository = MockLikesFeedRepository()

        let blurred = try await repository.fetchInbound(cursor: nil)
        #expect(blurred.items.allSatisfy { !$0.isVisible })

        try await repository.syncPremiumEntitlement(isActive: true)
        let revealed = try await repository.fetchInbound(cursor: nil)
        #expect(revealed.items.allSatisfy { $0.isVisible })

        try await repository.syncPremiumEntitlement(isActive: false)
        let reblurred = try await repository.fetchInbound(cursor: nil)
        #expect(reblurred.items.allSatisfy { !$0.isVisible })
    }
}
