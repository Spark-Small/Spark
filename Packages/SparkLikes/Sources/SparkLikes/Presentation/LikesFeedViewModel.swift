// Module: SparkLikes — Discover feed state.

import Foundation
import Observation
import SparkCore

@MainActor
@Observable
public final class LikesFeedViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(LikesUserFacingError)
    }

    public private(set) var cards: [DiscoverCard] = []
    public private(set) var loadState: LoadState = .idle
    public var currentIndex: Int = 0
    public var preferences: LikesPreferences
    public private(set) var isPerformingAction = false
    public private(set) var statusMessage: String?
    public private(set) var profileGateSaveError: LikesUserFacingError?
    public var pendingMatch: LikeActionResult?
    public var pendingMatchPeerName: String?
    public var pendingMatchCard: DiscoverCard?
    public var pendingDirectMessage: PendingDirectMessage?

    public private(set) var nextCursor: String?
    public private(set) var isLoadingMore = false

    public private(set) var inboundItems: [InboundLikeItem] = []
    public private(set) var inboundNextCursor: String?
    public private(set) var isLoadingMoreInbound = false
    public private(set) var viewerProfile: LikesViewerProfile = LikesViewerProfile()
    public var showProfileGate = false
    public var showOnboarding = false
    public private(set) var cardsBrowsedThisSession = 0
    public var showPreferencesHint = false

    let fetchFeed: FetchLikesFeedUseCase
    let fetchInbound: FetchInboundLikesUseCase
    let fetchViewerProfile: FetchViewerProfileUseCase
    let updateViewerProfile: UpdateViewerProfileUseCase
    let rewindPass: RewindPassUseCase
    let submitLike: SubmitLikeUseCase
    let submitPass: SubmitPassUseCase
    let submitFriendRequest: SubmitFriendRequestUseCase
    let reportAndBlockUser: ReportAndBlockUserUseCase
    private var loadGeneration = 0

    public init(repository: any LikesFeedRepository, preferences: LikesPreferences = LikesPreferencesStore.load()) {
        self.preferences = preferences
        fetchFeed = FetchLikesFeedUseCase(repository: repository)
        fetchInbound = FetchInboundLikesUseCase(repository: repository)
        fetchViewerProfile = FetchViewerProfileUseCase(repository: repository)
        updateViewerProfile = UpdateViewerProfileUseCase(repository: repository)
        rewindPass = RewindPassUseCase(repository: repository)
        submitLike = SubmitLikeUseCase(repository: repository)
        submitPass = SubmitPassUseCase(repository: repository)
        submitFriendRequest = SubmitFriendRequestUseCase(repository: repository)
        reportAndBlockUser = ReportAndBlockUserUseCase(repository: repository)
    }

    public var currentCard: DiscoverCard? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    public var inboundCount: Int { inboundItems.count }

    public var icebreakersForPendingMatch: [String] {
        guard let card = pendingMatchCard else { return [] }
        return LikesIcebreakerSuggestions.suggestions(for: card)
    }

    public func load() async {
        loadGeneration += 1
        let generation = loadGeneration
        loadState = .loading
        statusMessage = nil
        do {
            async let pageTask = fetchFeed(query: feedQuery(cursor: nil))
            async let inboundTask = fetchInbound(cursor: nil)
            async let profileTask = fetchViewerProfile()
            let (page, inbound, profile) = try await (pageTask, inboundTask, profileTask)
            guard generation == loadGeneration else { return }
            cards = page.items
            nextCursor = page.nextCursor
            inboundItems = inbound.items
            inboundNextCursor = inbound.nextCursor
            viewerProfile = profile
            currentIndex = 0
            cardsBrowsedThisSession = 0
            showPreferencesHint = false
            loadState = cards.isEmpty ? .empty : .loaded
            if !LikesOnboardingStore.hasSeenOnboarding {
                showOnboarding = true
            }
        } catch is CancellationError {
            return
        } catch {
            guard generation == loadGeneration else { return }
            loadState = .failure(LikesUserFacingError.from(error))
        }
    }

    public func reloadWithPreferences() async {
        LikesPreferencesStore.save(preferences)
        await load()
    }

    public func refreshInbound() async {
        do {
            let inbound = try await fetchInbound(cursor: nil)
            inboundItems = inbound.items
            inboundNextCursor = inbound.nextCursor
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func loadMoreInboundIfNeeded(currentItemID: String?) async {
        guard let cursor = inboundNextCursor,
              !isLoadingMoreInbound,
              let currentItemID,
              inboundItems.last?.id == currentItemID else {
            return
        }
        isLoadingMoreInbound = true
        defer { isLoadingMoreInbound = false }
        do {
            let inbound = try await fetchInbound(cursor: cursor)
            inboundNextCursor = inbound.nextCursor
            guard !inbound.items.isEmpty else { return }
            inboundItems.append(contentsOf: inbound.items)
        } catch is CancellationError {
            return
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func loadMoreIfNeeded(currentCardID: String?) async {
        guard loadState == .loaded,
              let cursor = nextCursor,
              !isLoadingMore,
              let currentCardID,
              cards.last?.id == currentCardID else {
            return
        }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let page = try await fetchFeed(query: feedQuery(cursor: cursor))
            nextCursor = page.nextCursor
            guard !page.items.isEmpty else { return }
            cards.append(contentsOf: page.items)
        } catch is CancellationError {
            return
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func guardDiscoverAction() -> Bool {
        guard viewerProfile.isComplete else {
            showProfileGate = true
            return false
        }
        return true
    }

    public func refreshInboundIfLoaded() async {
        guard loadState == .loaded || loadState == .empty else { return }
        await refreshInbound()
    }

    @discardableResult
    public func saveViewerProfile(_ profile: LikesViewerProfile) async -> Bool {
        profileGateSaveError = nil
        do {
            viewerProfile = try await updateViewerProfile(profile)
            LikesViewerProfileStore.markGateComplete(viewerProfile.isComplete)
            showProfileGate = false
            return true
        } catch {
            profileGateSaveError = LikesUserFacingError.from(error)
            return false
        }
    }

    public func markOnboardingSeen() {
        LikesOnboardingStore.markOnboardingSeen()
        showOnboarding = false
    }

    public func clearStatusMessage() {
        statusMessage = nil
    }

    func setStatusMessage(from error: Error) {
        statusMessage = LikesUserFacingError.from(error).message
    }

    // MARK: - Card actions

    enum LikePresentationSource: Sendable {
        case feed(advanceOnNonMatch: Bool)
        case inbound
    }

    public func advanceToNextCard() {
        guard !cards.isEmpty else { return }
        let removeIndex = min(currentIndex, cards.count - 1)
        cards.remove(at: removeIndex)
        if cards.isEmpty {
            currentIndex = 0
            loadState = .empty
            return
        }
        if currentIndex >= cards.count {
            currentIndex = cards.count - 1
        }
    }

    public func likeCurrentCard() async {
        guard guardDiscoverAction(), let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let result = try await submitLike(userID: card.userID)
            recordBrowseProgress()
            applyLikeResult(result, card: card, source: .feed(advanceOnNonMatch: true))
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func likeInboundUser(_ userID: UserID) async {
        guard guardDiscoverAction(), !isPerformingAction else { return }
        guard let card = inboundItems.first(where: { $0.userID == userID })?.card else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            let result = try await submitLike(userID: userID)
            inboundItems.removeAll { $0.userID == userID }
            applyLikeResult(result, card: card, source: .inbound)
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func passCurrentCard() async {
        guard let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            try await submitPass(userID: card.userID)
            recordBrowseProgress()
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func friendRequestCurrentCard() async {
        guard guardDiscoverAction(), let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            _ = try await submitFriendRequest(userID: card.userID)
            recordBrowseProgress()
            statusMessage = String(
                localized: "likes.friend.sent",
                defaultValue: "好友请求已发送",
                comment: "Friend request sent"
            )
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func rewindLastPass() async {
        guard !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            guard let card = try await rewindPass() else {
                statusMessage = String(
                    localized: "likes.error.rewindUnavailable",
                    defaultValue: "今天无法撤回，或没有可撤回的人",
                    comment: "Rewind unavailable"
                )
                return
            }
            LikesTelemetry.rewindUsed()
            if loadState == .empty {
                loadState = .loaded
            }
            cards.insert(card, at: min(currentIndex, cards.count))
            statusMessage = String(
                localized: "likes.rewind.done",
                defaultValue: "已撤回上一位",
                comment: "Rewind done"
            )
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func reportAndBlockCurrentCard(reason: LikesReportReason, detail: String?) async {
        guard let card = currentCard, !isPerformingAction else { return }
        isPerformingAction = true
        defer { isPerformingAction = false }
        do {
            try await reportAndBlockUser(userID: card.userID, reason: reason.wireValue, detail: detail)
            statusMessage = String(
                localized: "likes.report.done",
                defaultValue: "已举报并屏蔽",
                comment: "Report done"
            )
            advanceToNextCard()
        } catch {
            setStatusMessage(from: error)
        }
    }

    public func completeMatchWithMessage(_ message: String?) {
        if let message, !message.isEmpty {
            LikesTelemetry.firstMessageSent(source: "match_sheet")
        }
        clearMatchPresentation()
        advanceToNextCard()
    }

    public func dismissMatchWithoutMessage() {
        clearMatchPresentation()
        advanceToNextCard()
    }

    public func clearMatchPresentation() {
        pendingMatch = nil
        pendingMatchPeerName = nil
        pendingMatchCard = nil
    }

    public func clearDirectMessagePresentation() {
        pendingDirectMessage = nil
    }

    private func applyLikeResult(_ result: LikeActionResult, card: DiscoverCard, source: LikePresentationSource) {
        switch result.outcome {
        case .matched:
            presentMatch(result: result, card: card)
        case .pending:
            statusMessage = Self.pendingLikeStatusMessage
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        case .alreadyConnected:
            if let threadID = result.threadID {
                pendingDirectMessage = PendingDirectMessage(threadID: threadID, peerName: card.displayName)
            } else {
                statusMessage = Self.alreadyConnectedStatusMessage
            }
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        case .sent:
            if case .feed(advanceOnNonMatch: true) = source {
                advanceToNextCard()
            }
        }
    }

    private func presentMatch(result: LikeActionResult, card: DiscoverCard) {
        pendingMatch = result
        pendingMatchPeerName = card.displayName
        pendingMatchCard = card
        LikesTelemetry.matchSheetShown()
    }

    private func recordBrowseProgress() {
        cardsBrowsedThisSession += 1
        if cardsBrowsedThisSession >= 5, cards.count <= 1 {
            showPreferencesHint = true
        }
    }

    private static var pendingLikeStatusMessage: String {
        String(
            localized: "likes.like.pending",
            defaultValue: "已喜欢，等对方回应",
            comment: "Like pending"
        )
    }

    private static var alreadyConnectedStatusMessage: String {
        String(
            localized: "likes.like.connected",
            defaultValue: "你们已经可以聊天了",
            comment: "Already connected"
        )
    }

    private func feedQuery(cursor: String?) -> LikesFeedQuery {
        LikesFeedQuery(
            cursor: cursor,
            genderPreference: preferences.genderPreference,
            intent: preferences.intent
        )
    }
}

public struct PendingDirectMessage: Equatable, Sendable {
    public let threadID: String
    public let peerName: String

    public init(threadID: String, peerName: String) {
        self.threadID = threadID
        self.peerName = peerName
    }
}

public typealias LikesOpenConversationHandler = @Sendable (String, String, String?) async -> Void
