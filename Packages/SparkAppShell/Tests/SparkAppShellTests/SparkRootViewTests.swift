// Module: SparkAppShellTests

import SparkAppShell
import SparkAuth
import SparkActivity
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkPayments
import SparkPersistence
import SparkSearch
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
            messagesRepository: MockMessagesRepository(),
            activityFeedRepository: MockActivityFeedRepository(),
            activityBrowseRepository: MockActivityBrowseRepository(),
            likesFeedRepository: MockLikesFeedRepository(),
            searchRepository: MockSearchRepository(),
            communityPostsRepository: MockCommunityPostsRepository(),
            paywallRouter: PaywallRouter(appRouter: router)
        )
    }
}
