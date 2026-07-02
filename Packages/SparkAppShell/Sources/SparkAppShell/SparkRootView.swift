// Module: SparkAppShell — Application root with auth guard and tab shell.

import SparkAuth
import SparkActivity
import SparkCommunity
import SparkMessages
import SparkPayments
import SparkPersistence
import SparkProfile
import SparkBuddy
import SparkSearch
import SparkTrust
import SwiftUI

/// Routes between login and the four-tab shell based on `AuthViewModel.authState`.
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
                    .background(Color(.systemBackground))
            case .unauthenticated, .authenticated, .failure:
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
        .onChange(of: authViewModel.authState) { oldState, newState in
            guard case .authenticated = newState else { return }
            switch oldState {
            case .unauthenticated, .failure:
                router.finishAuthentication()
            default:
                break
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
            searchRepository: MockSearchRepository(),
            buddyRepository: MockBuddyRepository(),
            communityPostsRepository: MockCommunityPostsRepository(),
            trustRepository: MockTrustRepository(),
            blockedActivityHostsStore: BlockedActivityHostsStore()
        ),
        paywallRouter: PaywallRouter(appRouter: router)
    )
}
