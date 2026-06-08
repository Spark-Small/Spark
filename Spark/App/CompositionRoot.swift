// Module: Spark App — Dependency injection assembly.

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
import SparkProfile
import SparkSearch

/// Composition root for app-wide service registration.
enum CompositionRoot {
    private static var dependenciesStorage: AppDependencies?

    static var dependencies: AppDependencies {
        guard let dependenciesStorage else {
            fatalError("CompositionRoot.bootstrap() must run before accessing dependencies")
        }
        return dependenciesStorage
    }

    @MainActor
    static func bootstrapIfNeeded() {
        if dependenciesStorage == nil {
            bootstrap()
        }
    }

    @MainActor
    static func bootstrap() {
        let apiConfiguration = APIConfiguration.loadFromBundle()
        let tokenProvider = KeychainAccessTokenProvider()
        let sessionStore = AuthSessionStore()
        let httpClient = HTTPClient(
            configuration: apiConfiguration,
            interceptors: [AuthorizationInterceptor(tokenProvider: tokenProvider)]
        )
        let apiClient = APIClient(http: httpClient)
        let authService = makeAuthService(
            configuration: apiConfiguration,
            apiClient: apiClient,
            sessionStore: sessionStore,
            tokenProvider: tokenProvider
        )
        let messagesCache = MessagesCache()
        let messagesRepository = makeMessagesRepository(
            configuration: apiConfiguration,
            apiClient: apiClient,
            cache: messagesCache
        )
        let blockedActivityHostsStore = BlockedActivityHostsStore()
        let activityFeedRepository = makeActivityFeedRepository(
            configuration: apiConfiguration,
            apiClient: apiClient,
            blockedHostsStore: blockedActivityHostsStore
        )
        let activityBrowseRepository = makeActivityBrowseRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let likesFeedRepository = makeLikesFeedRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let profileRepository = makeProfileRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let searchRepository = makeSearchRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let communityPostsRepository = makeCommunityPostsRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let entitlementManager = makeEntitlementManager(
            configuration: apiConfiguration,
            apiClient: apiClient,
            storeKitService: makeStoreKitService(configuration: apiConfiguration)
        )
        let deviceTokenUploader = makeDeviceTokenUploader(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let discoverMediaImageCache = DiscoverMediaImageCache()

        dependenciesStorage = AppDependencies(
            apiConfiguration: apiConfiguration,
            tokenProvider: tokenProvider,
            sessionStore: sessionStore,
            httpClient: httpClient,
            apiClient: apiClient,
            authService: authService,
            messagesRepository: messagesRepository,
            activityFeedRepository: activityFeedRepository,
            activityBrowseRepository: activityBrowseRepository,
            likesFeedRepository: likesFeedRepository,
            profileRepository: profileRepository,
            searchRepository: searchRepository,
            communityPostsRepository: communityPostsRepository,
            storeKitService: makeStoreKitService(configuration: apiConfiguration),
            entitlementManager: entitlementManager,
            deviceTokenUploader: deviceTokenUploader,
            blockedActivityHostsStore: blockedActivityHostsStore,
            discoverMediaImageCache: discoverMediaImageCache
        )
    }

    private static func makeDeviceTokenUploader(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any DeviceTokenUploading {
        if configuration.usesMockBackend {
            return NoOpDeviceTokenUploader()
        }
        return LiveDeviceTokenUploader(apiClient: apiClient)
    }

    private static func makeAuthService(
        configuration: APIConfiguration,
        apiClient: APIClient,
        sessionStore: AuthSessionStore,
        tokenProvider: KeychainAccessTokenProvider
    ) -> any AuthService {
        if configuration.usesMockBackend {
            return MockAuthService(sessionStore: sessionStore, tokenProvider: tokenProvider)
        }
        return LiveAuthService(
            apiClient: apiClient,
            sessionStore: sessionStore,
            tokenProvider: tokenProvider
        )
    }

    private static func makeMessagesRepository(
        configuration: APIConfiguration,
        apiClient: APIClient,
        cache: MessagesCache
    ) -> any MessagesRepository {
        if configuration.usesMockBackend {
            return MockMessagesRepository(unreadCount: 3)
        }
        return LiveMessagesRepository(apiClient: apiClient, cache: cache)
    }

    private static func makeActivityFeedRepository(
        configuration: APIConfiguration,
        apiClient: APIClient,
        blockedHostsStore: BlockedActivityHostsStore
    ) -> any ActivityFeedRepository {
        if configuration.usesMockBackend {
            return MockActivityFeedRepository(blockedHostsStore: blockedHostsStore)
        }
        return LiveActivityFeedRepository(apiClient: apiClient)
    }

    private static func makeActivityBrowseRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any ActivityBrowseRepository {
        if configuration.usesMockBackend {
            return MockActivityBrowseRepository()
        }
        return LiveActivityBrowseRepository(apiClient: apiClient)
    }

    private static func makeLikesFeedRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any LikesFeedRepository {
        if configuration.usesMockBackend {
            return MockLikesFeedRepository()
        }
        return LiveLikesFeedRepository(apiClient: apiClient)
    }

    private static func makeProfileRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any ProfileRepository {
        if configuration.usesMockBackend {
            return MockProfileRepository()
        }
        return LiveProfileRepository(apiClient: apiClient)
    }

    private static func makeSearchRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any SearchRepository {
        if configuration.usesMockBackend {
            return MockSearchRepository()
        }
        return LiveSearchRepository(apiClient: apiClient)
    }

    private static func makeCommunityPostsRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any CommunityPostsRepository {
        if configuration.usesMockBackend {
            return MockCommunityPostsRepository()
        }
        return LiveCommunityPostsRepository(apiClient: apiClient)
    }

    private static func makeEntitlementManager(
        configuration: APIConfiguration,
        apiClient: APIClient,
        storeKitService: any StoreKitServing
    ) -> EntitlementManager {
        guard SparkFeatureFlags.isCNPaymentsEnabled else {
            return EntitlementManager(storeKit: storeKitService)
        }
        return EntitlementManager(
            storeKit: storeKitService,
            paymentRepository: makePaymentRepository(configuration: configuration, apiClient: apiClient),
            cnPaymentCoordinators: LiveCNPaymentCoordinatorsFactory.make(configuration: configuration)
        )
    }

    private static func makeStoreKitService(configuration: APIConfiguration) -> any StoreKitServing {
        if configuration.usesMockBackend {
            return MockStoreKitService()
        }
        return LiveStoreKitService()
    }

    private static func makePaymentRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any PaymentRepository {
        if configuration.usesMockBackend {
            return MockPaymentRepository()
        }
        return LivePaymentRepository(apiClient: apiClient)
    }
}
