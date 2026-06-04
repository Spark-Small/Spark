// Module: SparkAppShell — Application root with auth guard and tab shell.

import SparkAuth
import SparkActivity
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkPayments
import SparkPersistence
import SparkSearch
import SwiftUI

/// Routes between login and the five-tab shell based on `AuthViewModel.authState`.
public struct SparkRootView: View {
    @Bindable var authViewModel: AuthViewModel
    @Bindable var router: AppRouter
    @Bindable var entitlementManager: EntitlementManager
    let messagesRepository: any MessagesRepository
    let activityFeedRepository: any ActivityFeedRepository
    let likesFeedRepository: any LikesFeedRepository
    let searchRepository: any SearchRepository
    let communityPostsRepository: any CommunityPostsRepository
    let paywallRouter: PaywallRouter

    public init(
        authViewModel: AuthViewModel,
        router: AppRouter,
        entitlementManager: EntitlementManager,
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        likesFeedRepository: any LikesFeedRepository,
        searchRepository: any SearchRepository,
        communityPostsRepository: any CommunityPostsRepository,
        paywallRouter: PaywallRouter
    ) {
        self.authViewModel = authViewModel
        self.router = router
        self.entitlementManager = entitlementManager
        self.messagesRepository = messagesRepository
        self.activityFeedRepository = activityFeedRepository
        self.likesFeedRepository = likesFeedRepository
        self.searchRepository = searchRepository
        self.communityPostsRepository = communityPostsRepository
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
                    messagesRepository: messagesRepository,
                    activityFeedRepository: activityFeedRepository,
                    likesFeedRepository: likesFeedRepository,
                    searchRepository: searchRepository,
                    communityPostsRepository: communityPostsRepository,
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
        authViewModel: AuthViewModel(authService: service),
        router: router,
        entitlementManager: EntitlementManager(storeKit: MockStoreKitService()),
        messagesRepository: MockMessagesRepository(),
        activityFeedRepository: MockActivityFeedRepository(),
        likesFeedRepository: MockLikesFeedRepository(),
        searchRepository: MockSearchRepository(),
        communityPostsRepository: MockCommunityPostsRepository(),
        paywallRouter: PaywallRouter(appRouter: router)
    )
}
