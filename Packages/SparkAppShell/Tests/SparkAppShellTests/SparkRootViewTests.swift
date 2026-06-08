// Module: SparkAppShellTests

import SparkAppShell
import SparkAuth
import SparkActivity
import SparkCommunity
import SparkMessages
import SparkPayments
import SparkPersistence
import SparkSearch
import SparkProfile
import SparkTrust
import Testing

@Suite(.serialized)
@MainActor
struct SparkRootViewTests {
    @Test func rootViewInitializes() {
        let service = MockAuthService(
            sessionStore: AuthSessionStore(),
            tokenProvider: KeychainAccessTokenProvider(
                keychain: KeychainManager(service: "com.spark.shell.tests")
            )
        )
        let router = AppRouter()
        _ = SparkRootView(
            authViewModel: AuthViewModel(authService: service),
            router: router,
            entitlementManager: EntitlementManager(storeKit: MockStoreKitService()),
            tabDependencies: SparkTabDependencies(
                messagesRepository: MockMessagesRepository(),
                activityFeedRepository: MockActivityFeedRepository(),
                activityBrowseRepository: MockActivityBrowseRepository(),
                searchRepository: MockSearchRepository(),
                communityPostsRepository: MockCommunityPostsRepository(),
                trustRepository: MockTrustRepository(),
                userContextRepository: MockUserContextRepository(),
                blockedActivityHostsStore: BlockedActivityHostsStore()
            ),
            paywallRouter: PaywallRouter(appRouter: router)
        )
    }
}
