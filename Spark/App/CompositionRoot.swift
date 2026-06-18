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
import SparkProfile
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
        let authSessionBroadcaster = AuthSessionInvalidationBroadcaster()
        let httpClient = HTTPClient(
            configuration: apiConfiguration,
            interceptors: [
                AuthorizationInterceptor(tokenProvider: tokenProvider),
                UnauthorizedSessionInterceptor(invalidator: authSessionBroadcaster),
            ]
        )
        let apiClient = APIClient(http: httpClient)
        let authService = makeAuthService(
            configuration: apiConfiguration,
            apiClient: apiClient,
            sessionStore: sessionStore,
            tokenProvider: tokenProvider
        )
        let repos = assembleTabRepositories(configuration: apiConfiguration, apiClient: apiClient)
        let storeKitService = makeStoreKitService(configuration: apiConfiguration)
        let entitlementManager = EntitlementManager(storeKit: storeKitService)
        let deviceTokenUploader = makeDeviceTokenUploader(
            configuration: apiConfiguration,
            apiClient: apiClient
        )
        let remoteImageCache = RemoteImageCache(httpClient: httpClient, configuration: .thumbnail)
        let authCoordinator = AuthCoordinator(
            authService: authService,
            thirdPartySignInCoordinator: ThirdPartySignInCoordinator(
                policy: apiConfiguration.usesMockBackend ? .mockOAuthCode : .stagingOAuthCode
            )
        )

        return AppDependencies(
            apiConfiguration: apiConfiguration,
            tokenProvider: tokenProvider,
            sessionStore: sessionStore,
            authSessionBroadcaster: authSessionBroadcaster,
            httpClient: httpClient,
            apiClient: apiClient,
            authService: authService,
            authCoordinator: authCoordinator,
            tabDependencies: repos.tabDependencies,
            messagesRepository: repos.messagesRepository,
            activityFeedRepository: repos.activityFeedRepository,
            activityBrowseRepository: repos.activityBrowseRepository,
            searchRepository: repos.searchRepository,
            communityPostsRepository: repos.communityPostsRepository,
            trustRepository: repos.trustRepository,
            storeKitService: storeKitService,
            entitlementManager: entitlementManager,
            deviceTokenUploader: deviceTokenUploader,
            blockedActivityHostsStore: repos.blockedActivityHostsStore,
            remoteImageCache: remoteImageCache
        )
    }

    private struct TabRepositories {
        let tabDependencies: SparkTabDependencies
        let messagesRepository: any MessagesRepository
        let activityFeedRepository: any ActivityFeedRepository
        let activityBrowseRepository: any ActivityBrowseRepository
        let searchRepository: any SearchRepository
        let communityPostsRepository: any CommunityPostsRepository
        let trustRepository: any TrustRepository
        let blockedActivityHostsStore: BlockedActivityHostsStore
    }

    @MainActor
    private static func assembleTabRepositories(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> TabRepositories {
        let messagesCache = MessagesCache()
        let messagesRepository = makeMessagesRepository(
            configuration: configuration,
            apiClient: apiClient,
            cache: messagesCache
        )
        let blockedActivityHostsStore = BlockedActivityHostsStore()
        let activityFeedRepository = makeActivityFeedRepository(
            configuration: configuration,
            apiClient: apiClient,
            blockedHostsStore: blockedActivityHostsStore
        )
        let activityBrowseRepository = makeActivityBrowseRepository(
            configuration: configuration,
            apiClient: apiClient
        )
        let searchRepository = makeSearchRepository(configuration: configuration, apiClient: apiClient)
        let communityPostsRepository = makeCommunityPostsRepository(
            configuration: configuration,
            apiClient: apiClient
        )
        let trustRepository = makeTrustRepository(configuration: configuration, apiClient: apiClient)
        let userContextRepository = makeUserContextRepository(
            configuration: configuration,
            apiClient: apiClient
        )
        let prepareCommunityMediaUpload: any PrepareCommunityMediaUploadUseCaseProtocol =
            configuration.usesMockBackend
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
            userContextRepository: userContextRepository,
            blockedActivityHostsStore: blockedActivityHostsStore
        )
        return TabRepositories(
            tabDependencies: tabDependencies,
            messagesRepository: messagesRepository,
            activityFeedRepository: activityFeedRepository,
            activityBrowseRepository: activityBrowseRepository,
            searchRepository: searchRepository,
            communityPostsRepository: communityPostsRepository,
            trustRepository: trustRepository,
            blockedActivityHostsStore: blockedActivityHostsStore
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

    private static func makeUserContextRepository(
        configuration: APIConfiguration,
        apiClient: APIClient
    ) -> any UserContextRepository {
        if configuration.usesMockBackend {
            return MockUserContextRepository()
        }
        return LiveUserContextRepository(apiClient: apiClient)
    }

    private static func makeStoreKitService(configuration: APIConfiguration) -> any StoreKitServing {
        if configuration.usesMockBackend {
            return MockStoreKitService()
        }
        return LiveStoreKitService()
    }
}
