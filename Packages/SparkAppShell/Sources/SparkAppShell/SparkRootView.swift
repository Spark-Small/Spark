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
import SwiftUI

/// Routes between login and the five-tab shell based on `AuthViewModel.authState`.
public struct SparkRootView: View {
    @Bindable var authViewModel: AuthViewModel
    @Bindable var router: AppRouter
    @Bindable var entitlementManager: EntitlementManager
    let messagesRepository: any MessagesRepository
    let activityFeedRepository: any ActivityFeedRepository
    let activityBrowseRepository: any ActivityBrowseRepository
    let likesFeedRepository: any LikesFeedRepository
    let profileRepository: any ProfileRepository
    let searchRepository: any SearchRepository
    let communityPostsRepository: any CommunityPostsRepository
    let paywallRouter: PaywallRouter
    let blockedActivityHostsStore: BlockedActivityHostsStore
    let discoverMediaImageCache: DiscoverMediaImageCache

    public init(
        authViewModel: AuthViewModel,
        router: AppRouter,
        entitlementManager: EntitlementManager,
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        activityBrowseRepository: any ActivityBrowseRepository,
        likesFeedRepository: any LikesFeedRepository,
        profileRepository: any ProfileRepository = MockProfileRepository(),
        searchRepository: any SearchRepository,
        communityPostsRepository: any CommunityPostsRepository,
        paywallRouter: PaywallRouter,
        blockedActivityHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        discoverMediaImageCache: DiscoverMediaImageCache = DiscoverMediaImageCache()
    ) {
        self.authViewModel = authViewModel
        self.router = router
        self.entitlementManager = entitlementManager
        self.messagesRepository = messagesRepository
        self.activityFeedRepository = activityFeedRepository
        self.activityBrowseRepository = activityBrowseRepository
        self.likesFeedRepository = likesFeedRepository
        self.profileRepository = profileRepository
        self.searchRepository = searchRepository
        self.communityPostsRepository = communityPostsRepository
        self.paywallRouter = paywallRouter
        self.blockedActivityHostsStore = blockedActivityHostsStore
        self.discoverMediaImageCache = discoverMediaImageCache
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
                    activityBrowseRepository: activityBrowseRepository,
                    likesFeedRepository: likesFeedRepository,
                    profileRepository: profileRepository,
                    searchRepository: searchRepository,
                    communityPostsRepository: communityPostsRepository,
                    paywallRouter: paywallRouter,
                    blockedActivityHostsStore: blockedActivityHostsStore,
                    discoverMediaImageCache: discoverMediaImageCache
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
        authViewModel: AuthViewModel(authService: service, cnCoordinators: .preview),
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
