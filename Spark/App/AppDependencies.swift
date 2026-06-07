// Module: Spark App — Wired services created at launch.

import Foundation
import SparkAuth
import SparkCore
import SparkActivity
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkNetworking
import SparkPayments
import SparkPersistence
import SparkSearch
import SparkTrust
import SparkNotifications
import SparkAppShell

/// Container for composition-root dependencies (injected via SwiftUI environment).
public struct AppDependencies {
    public let apiConfiguration: APIConfiguration
    public let tokenProvider: KeychainAccessTokenProvider
    public let sessionStore: AuthSessionStore
    public let httpClient: HTTPClient
    public let apiClient: APIClient
    public let authService: any AuthService
    public let authCoordinator: AuthCoordinator
    public let tabDependencies: SparkTabDependencies
    public let messagesRepository: any MessagesRepository
    public let activityFeedRepository: any ActivityFeedRepository
    public let activityBrowseRepository: any ActivityBrowseRepository
    public let likesFeedRepository: any LikesFeedRepository
    public let searchRepository: any SearchRepository
    public let communityPostsRepository: any CommunityPostsRepository
    public let trustRepository: any TrustRepository
    public let storeKitService: any StoreKitServing
    // REASONING: EntitlementManager is MainActor-isolated; held by App and passed into views.
    public let entitlementManager: EntitlementManager
    public let deviceTokenUploader: any DeviceTokenUploading
    public let blockedActivityHostsStore: BlockedActivityHostsStore
    public let discoverMediaImageCache: DiscoverMediaImageCache
    public let remoteImageCache: RemoteImageCache
    public let likesPreferencesStore: any LikesPreferencesStoring
    public let likesOnboardingPreferences: any LikesOnboardingPreferences

    public init(
        apiConfiguration: APIConfiguration,
        tokenProvider: KeychainAccessTokenProvider,
        sessionStore: AuthSessionStore,
        httpClient: HTTPClient,
        apiClient: APIClient,
        authService: any AuthService,
        authCoordinator: AuthCoordinator,
        tabDependencies: SparkTabDependencies,
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        activityBrowseRepository: any ActivityBrowseRepository,
        likesFeedRepository: any LikesFeedRepository,
        searchRepository: any SearchRepository,
        communityPostsRepository: any CommunityPostsRepository,
        trustRepository: any TrustRepository,
        storeKitService: any StoreKitServing,
        entitlementManager: EntitlementManager,
        deviceTokenUploader: any DeviceTokenUploading,
        blockedActivityHostsStore: BlockedActivityHostsStore,
        discoverMediaImageCache: DiscoverMediaImageCache,
        remoteImageCache: RemoteImageCache,
        likesPreferencesStore: any LikesPreferencesStoring,
        likesOnboardingPreferences: any LikesOnboardingPreferences
    ) {
        self.apiConfiguration = apiConfiguration
        self.tokenProvider = tokenProvider
        self.sessionStore = sessionStore
        self.httpClient = httpClient
        self.apiClient = apiClient
        self.authService = authService
        self.authCoordinator = authCoordinator
        self.tabDependencies = tabDependencies
        self.messagesRepository = messagesRepository
        self.activityFeedRepository = activityFeedRepository
        self.activityBrowseRepository = activityBrowseRepository
        self.likesFeedRepository = likesFeedRepository
        self.searchRepository = searchRepository
        self.communityPostsRepository = communityPostsRepository
        self.trustRepository = trustRepository
        self.storeKitService = storeKitService
        self.entitlementManager = entitlementManager
        self.deviceTokenUploader = deviceTokenUploader
        self.blockedActivityHostsStore = blockedActivityHostsStore
        self.discoverMediaImageCache = discoverMediaImageCache
        self.remoteImageCache = remoteImageCache
        self.likesPreferencesStore = likesPreferencesStore
        self.likesOnboardingPreferences = likesOnboardingPreferences
    }
}
