// Module: SparkAppShell — Application root with auth guard and tab shell.

import SparkAuth
import SparkActivity
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkPayments
import SparkPersistence
import SparkProfile
import SparkSearch
import SparkTrust
import SwiftUI

/// Routes between login and the five-tab shell based on `AuthViewModel.authState`.
public struct SparkRootView: View {
    @Bindable var authViewModel: AuthViewModel
    @Bindable var router: AppRouter
    @Bindable var entitlementManager: EntitlementManager
    let tabDependencies: SparkTabDependencies
    let paywallRouter: PaywallRouter

    public init(
        authViewModel: AuthViewModel,
        router: AppRouter,
        entitlementManager: EntitlementManager,
        tabDependencies: SparkTabDependencies,
        paywallRouter: PaywallRouter
    ) {
        self.authViewModel = authViewModel
        self.router = router
        self.entitlementManager = entitlementManager
        self.tabDependencies = tabDependencies
        self.paywallRouter = paywallRouter
    }

    public var body: some View {
        Group {
            switch authViewModel.authState {
            case .idle, .loading:
                ProgressView()
                    .progressViewStyle(.circular)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.regularMaterial)
            case .unauthenticated, .failure:
                LoginView(viewModel: authViewModel)
            case .authenticated:
                SparkMainTabView(
                    router: router,
                    authViewModel: authViewModel,
                    entitlementManager: entitlementManager,
                    tabDependencies: tabDependencies,
                    paywallRouter: paywallRouter
                )
            }
        }
        .task {
            await authViewModel.restoreSessionIfNeeded()
        }
        .onChange(of: authViewModel.authState) { _, newState in
            if case .authenticated = newState, let pending = router.pendingDeepLinkAfterAuth {
                router.apply(pending)
                router.pendingDeepLinkAfterAuth = nil
            }
        }
    }
}

#Preview("Auth shell") {
    let store = AuthSessionStore()
    let tokenProvider = KeychainAccessTokenProvider()
    let service = MockAuthService(sessionStore: store, tokenProvider: tokenProvider)
    let router = AppRouter()
    SparkRootView(
        authViewModel: AuthCoordinator(authService: service).makeAuthViewModel(),
        router: router,
        entitlementManager: EntitlementManager(storeKit: MockStoreKitService()),
        tabDependencies: SparkTabDependencies(
            messagesRepository: MockMessagesRepository(),
            activityFeedRepository: MockActivityFeedRepository(),
            activityBrowseRepository: MockActivityBrowseRepository(),
            likesFeedRepository: MockLikesFeedRepository(),
            searchRepository: MockSearchRepository(),
            communityPostsRepository: MockCommunityPostsRepository(),
            trustRepository: MockTrustRepository(),
            blockedActivityHostsStore: BlockedActivityHostsStore(),
            discoverMediaImageCache: DiscoverMediaImageCache.previewInstance(),
            likesPreferencesStore: InMemoryLikesPreferencesStore(),
            likesOnboardingPreferences: InMemoryLikesOnboardingPreferences()
        ),
        paywallRouter: PaywallRouter(appRouter: router)
    )
}
