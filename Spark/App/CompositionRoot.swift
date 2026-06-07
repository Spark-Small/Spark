// Module: Spark App — Dependency injection assembly.

import Foundation
import SparkAuth
import SparkCore
import SparkActivity
import SparkCommunity
import SparkMessages
import SparkNetworking
import SparkPayments
import SparkPersistence
import SparkSearch
import SparkTrust
import SparkNotifications
import SparkAppShell

enum CompositionRoot {
    static func bootstrapAsync() async -> AppDependencies {
        let apiConfiguration = await Task.detached(priority: .userInitiated) {
            APIConfiguration.loadFromBundle()
        }.value
        return await MainActor.run {
            assemble(apiConfiguration: apiConfiguration)
        }
    }

    @MainActor
    static func bootstrap() -> AppDependencies {
        assemble(apiConfiguration: APIConfiguration.loadFromBundle())
    }

    @MainActor
    private static func assemble(apiConfiguration: APIConfiguration) -> AppDependencies {
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
        let searchRepository = makeSearchRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let communityPostsRepository = makeCommunityPostsRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let trustRepository = makeTrustRepository(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let storeKitService = makeStoreKitService(configuration: apiConfiguration)
        let entitlementManager = EntitlementManager(storeKit: storeKitService)
        let deviceTokenUploader = makeDeviceTokenUploader(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let remoteImageCache = RemoteImageCache(httpClient: httpClient, configuration: .thumbnail)
        let authCoordinator = AuthCoordinator(authService: authService)
        let prepareCommunityMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol =
            apiConfiguration.usesMockBackend
                ? PrepareCommunityMediaUploadUseCase()
                : LivePrepareCommunityMediaUploadUseCase(apiClient: apiClient)
        let tabDependencies = SparkTabDependencies(
            messagesRepository: messagesRepository,
            activityFeedRepository: activityFeedRepository,
            activityBrowseRepository: activityBrowseRepository,
            searchRepository: searchRepository,
            communityPostsRepository: communityPostsRepository,
            prepareCommunityMediaUpload: prepareCommunityMediaUpload,
            trustRepository: trustRepository,
            blockedActivityHostsStore: blockedActivityHostsStore
        )

        return AppDependencies(
            apiConfiguration: apiConfiguration,
            tokenProvider: tokenProvider,
            sessionStore: sessionStore,
            httpClient: httpClient,
            apiClient: apiClient,
            authService: authService,
            authCoordinator: authCoordinator,
            tabDependencies: tabDependencies,
            messagesRepository: messagesRepository,
            activityFeedRepository: activityFeedRepository,
            activityBrowseRepository: activityBrowseRepository,
            searchRepository: searchRepository,
            communityPostsRepository: communityPostsRepository,
            trustRepository: trustRepository,
            storeKitService: storeKitService,
            entitlementManager: entitlementManager,
            deviceTokenUploader: deviceTokenUploader,
            blockedActivityHostsStore: blockedActivityHostsStore,
            remoteImageCache: remoteImageCache
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

    private static func makeTrustRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any TrustRepository {
        if configuration.usesMockBackend {
            return MockTrustRepository(initialCompleted: [.phone, .realName])
        }
        return LiveTrustRepository(apiClient: apiClient)
    }

    private static func makeStoreKitService(configuration: APIConfiguration) -> any StoreKitServing {
        if configuration.usesMockBackend {
            return MockStoreKitService()
        }
        return LiveStoreKitService()
    }
}
