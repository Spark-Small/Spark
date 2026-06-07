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

    public package(set) var cards: [DiscoverCard] = []
    public package(set) var loadState: LoadState = .idle
    public var currentIndex: Int = 0
    public var preferences: LikesPreferences
    public package(set) var isPerformingAction = false
    public package(set) var statusMessage: String?
    public package(set) var profileGateSaveError: LikesUserFacingError?
    public var pendingMatch: LikeActionResult?
    public var pendingMatchPeerName: String?
    public var pendingMatchCard: DiscoverCard?
    public var pendingDirectMessage: PendingDirectMessage?

    public package(set) var nextCursor: String?
    public package(set) var isLoadingMore = false

    public package(set) var inboundItems: [InboundLikeItem] = []
    public package(set) var sortedInboundItems: [InboundLikeItem] = []
    public package(set) var inboundNextCursor: String?
    public package(set) var isLoadingMoreInbound = false
    public package(set) var viewerProfile: LikesViewerProfile = LikesViewerProfile()
    public var showProfileGate = false
    public var showOnboarding = false
    public package(set) var cardsBrowsedThisSession = 0
    public var showPreferencesHint = false
    public package(set) var dailyStats = DailyLikeStats(
        todaySeenCount: 0,
        dailyPoolSize: 50,
        sparkChargesRemaining: 3
    )
    public var pendingOpener: String?
    public var pendingLikedQuestionID: String?
    public var sparkBurstToken = 0
    public var friendRequestSuccessToken = 0

    let fetchFeed: any FetchLikesFeedUseCaseProtocol
    let fetchInbound: any FetchInboundLikesUseCaseProtocol
    let fetchViewerProfile: any FetchViewerProfileUseCaseProtocol
    let updateViewerProfile: any UpdateViewerProfileUseCaseProtocol
    let rewindPass: any RewindPassUseCaseProtocol
    let submitLike: any SubmitLikeUseCaseProtocol
    let fetchDailyStats: any FetchDailyLikeStatsUseCaseProtocol
    let requestAvatarUpload: any RequestAvatarUploadUseCaseProtocol
    let submitPass: any SubmitPassUseCaseProtocol
    let submitFriendRequest: any SubmitFriendRequestUseCaseProtocol
    let reportUser: any ReportUserUseCaseProtocol
    let blockUser: any BlockUserUseCaseProtocol
    private let preferencesStore: any LikesPreferencesStoring
    private let onboardingPreferences: any LikesOnboardingPreferences
    private var loadGeneration = 0

    public init(
        useCases: LikesFeedUseCases,
        preferencesStore: any LikesPreferencesStoring,
        onboardingPreferences: any LikesOnboardingPreferences
    ) {
        preferences = preferencesStore.load()
        self.preferencesStore = preferencesStore
        self.onboardingPreferences = onboardingPreferences
        fetchFeed = useCases.fetchFeed
        fetchInbound = useCases.fetchInbound
        fetchViewerProfile = useCases.fetchViewerProfile
        updateViewerProfile = useCases.updateViewerProfile
        rewindPass = useCases.rewindPass
        submitLike = useCases.submitLike
        fetchDailyStats = useCases.fetchDailyStats
        requestAvatarUpload = useCases.requestAvatarUpload
        submitPass = useCases.submitPass
        submitFriendRequest = useCases.submitFriendRequest
        reportUser = useCases.reportUser
        blockUser = useCases.blockUser
    }

    public convenience init(
        repository: any LikesFeedRepository,
        preferencesStore: any LikesPreferencesStoring,
        onboardingPreferences: any LikesOnboardingPreferences
    ) {
        let coordinator = LikesCoordinator(
            repository: repository,
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences,
            discoverMediaImageCache: DiscoverMediaImageCache.previewInstance()
        )
        self.init(
            useCases: coordinator.makeFeedUseCases(),
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences
        )
    }

    public var currentCard: DiscoverCard? {
        guard currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    public var inboundCount: Int { inboundItems.count }

    public var isDailyPoolExhausted: Bool {
        dailyStats.isPoolExhausted
    }

    public var openerSuggestions: [String] {
        guard let card = currentCard else { return [] }
        return LikesOpenerSuggestions.suggestions(for: card)
    }

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
            async let statsTask = fetchDailyStats()
            let (page, inbound, profile, stats) = try await (pageTask, inboundTask, profileTask, statsTask)
            guard generation == loadGeneration else { return }
            cards = page.items
            nextCursor = page.nextCursor
            inboundItems = inbound.items
            inboundNextCursor = inbound.nextCursor
            refreshSortedInbound()
            viewerProfile = profile
            dailyStats = stats
            currentIndex = 0
            cardsBrowsedThisSession = 0
            showPreferencesHint = false
            loadState = cards.isEmpty ? .empty : .loaded
            if !onboardingPreferences.hasSeenOnboarding {
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
        preferencesStore.save(preferences)
        await load()
    }

    public func refreshInbound() async {
        do {
            let inbound = try await fetchInbound(cursor: nil)
            inboundItems = inbound.items
            inboundNextCursor = inbound.nextCursor
            refreshSortedInbound()
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
            refreshSortedInbound()
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
        onboardingPreferences.markOnboardingSeen()
        showOnboarding = false
    }

    public func clearStatusMessage() {
        statusMessage = nil
    }

    public static let maxAvatarJPEGBytes = 1_048_576

    /// When `upload_url` is set, PUT JPEG bytes before saving `avatar_url` (MODULE-F).
    public func uploadAvatarJPEG(_ data: Data) async -> Bool {
        guard !data.isEmpty else { return false }
        guard data.count <= Self.maxAvatarJPEGBytes else {
            statusMessage = String(
                localized: "likes.avatar.tooLarge",
                defaultValue: "头像不能超过 1 MB",
                comment: "Avatar size limit"
            )
            return false
        }
        do {
            let prepared = try await requestAvatarUpload(contentType: "image/jpeg")
            if let uploadURL = prepared.uploadURL {
                try await AvatarUploadTransport.put(data: data, to: uploadURL, contentType: "image/jpeg")
            }
            var profile = viewerProfile
            profile = LikesViewerProfile(
                displayName: profile.displayName,
                hasPhoto: true,
                avatarURL: prepared.avatarURL
            )
            return await saveViewerProfile(profile)
        } catch {
            setStatusMessage(from: error)
            return false
        }
    }

    func setStatusMessage(from error: Error) {
        statusMessage = LikesUserFacingError.from(error).message
    }

    func refreshDailyStats() async {
        do {
            dailyStats = try await fetchDailyStats()
        } catch {
            setStatusMessage(from: error)
        }
    }

    func refreshSortedInbound() {
        sortedInboundItems = inboundItems.sorted(by: Self.inboundSort)
    }

    private static func inboundSort(_ lhs: InboundLikeItem, _ rhs: InboundLikeItem) -> Bool {
        if lhs.intensity != rhs.intensity {
            if lhs.intensity == .spark { return true }
            if rhs.intensity == .spark { return false }
        }
        let lhsHasOpener = lhs.opener?.isEmpty == false
        let rhsHasOpener = rhs.opener?.isEmpty == false
        if lhsHasOpener != rhsHasOpener {
            return lhsHasOpener
        }
        return (lhs.likedAt ?? .distantPast) > (rhs.likedAt ?? .distantPast)
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
