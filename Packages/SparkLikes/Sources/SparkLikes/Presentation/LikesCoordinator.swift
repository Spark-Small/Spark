// Module: SparkLikes — ViewModel factory; keeps Repository out of SwiftUI Views.

import Foundation
import SparkCore

public struct LikesCoordinator: Sendable {
    private let repository: any LikesFeedRepository
    private let preferencesStore: any LikesPreferencesStoring
    private let onboardingPreferences: any LikesOnboardingPreferences
    private let discoverMediaImageCache: DiscoverMediaImageCache

    public init(
        repository: any LikesFeedRepository,
        preferencesStore: any LikesPreferencesStoring,
        onboardingPreferences: any LikesOnboardingPreferences,
        discoverMediaImageCache: DiscoverMediaImageCache
    ) {
        self.repository = repository
        self.preferencesStore = preferencesStore
        self.onboardingPreferences = onboardingPreferences
        self.discoverMediaImageCache = discoverMediaImageCache
    }

    public var mediaImageCache: DiscoverMediaImageCache { discoverMediaImageCache }

    func makeFeedUseCases() -> LikesFeedUseCases {
        LikesFeedUseCases(
            fetchFeed: FetchLikesFeedUseCase(repository: repository),
            fetchInbound: FetchInboundLikesUseCase(repository: repository),
            fetchViewerProfile: FetchViewerProfileUseCase(repository: repository),
            updateViewerProfile: UpdateViewerProfileUseCase(repository: repository),
            rewindPass: RewindPassUseCase(repository: repository),
            submitLike: SubmitLikeUseCase(repository: repository),
            fetchDailyStats: FetchDailyLikeStatsUseCase(repository: repository),
            requestAvatarUpload: RequestAvatarUploadUseCase(repository: repository),
            submitPass: SubmitPassUseCase(repository: repository),
            submitFriendRequest: SubmitFriendRequestUseCase(repository: repository),
            reportUser: ReportUserUseCase(repository: repository),
            blockUser: BlockUserUseCase(repository: repository)
        )
    }

    @MainActor
    public func makeFeedViewModel() -> LikesFeedViewModel {
        LikesFeedViewModel(
            useCases: makeFeedUseCases(),
            preferencesStore: preferencesStore,
            onboardingPreferences: onboardingPreferences
        )
    }

    public func submitLike(_ request: SendLikeRequest) async throws -> LikeActionResult {
        try await SubmitLikeUseCase(repository: repository)(request)
    }

    public func syncPremiumEntitlement(isActive: Bool) async throws {
        try await SyncPremiumEntitlementUseCase(repository: repository)(isActive: isActive)
    }
}
