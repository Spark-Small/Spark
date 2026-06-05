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
