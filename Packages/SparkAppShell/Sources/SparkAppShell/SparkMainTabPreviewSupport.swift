// Module: SparkAppShell — Preview helpers for SparkMainTabView.

import SparkActivity
import SparkAuth
import SparkCommunity
import SparkDesignSystem
import SparkMessages
import SparkNetworking
import SparkPayments
import SparkPersistence
import SparkSearch
import SparkTrust
import SwiftUI

@MainActor
enum SparkMainTabPreviewSupport {
    static func makeAuthenticatedViewModel() -> AuthViewModel {
        let service = MockAuthService(
            sessionStore: AuthSessionStore(),
            tokenProvider: KeychainAccessTokenProvider()
        )
        service.simulatedDelayNanoseconds = 0
        let viewModel = AuthCoordinator(authService: service).makeAuthViewModel()
        viewModel.email = "test@spark.app"
        viewModel.password = "secret1"
        return viewModel
    }

    static func makeTabDependencies() -> SparkTabDependencies {
        SparkTabDependencies(
            messagesRepository: MockMessagesRepository(),
            activityFeedRepository: MockActivityFeedRepository(),
            activityBrowseRepository: MockActivityBrowseRepository(),
            searchRepository: MockSearchRepository(),
            communityPostsRepository: MockCommunityPostsRepository(),
            trustRepository: MockTrustRepository(),
            blockedActivityHostsStore: BlockedActivityHostsStore()
        )
    }

    static func tabView(authViewModel: AuthViewModel) -> SparkMainTabView {
        let router = AppRouter()
        return SparkMainTabView(
            router: router,
            authViewModel: authViewModel,
            entitlementManager: EntitlementManager(storeKit: MockStoreKitService()),
            tabDependencies: makeTabDependencies(),
            paywallRouter: PaywallRouter(appRouter: router)
        )
    }
}

private struct SparkMainTabPreviewContainer: View {
    @State private var authViewModel = SparkMainTabPreviewSupport.makeAuthenticatedViewModel()
    @State private var didSignIn = false

    var body: some View {
        SparkMainTabPreviewSupport.tabView(authViewModel: authViewModel)
            .environment(\.remoteImageCache, RemoteImageCache.previewInstance())
            .task {
                guard !didSignIn else { return }
                didSignIn = true
                await authViewModel.signInWithEmailTapped()
            }
    }
}

#Preview("Main tabs") {
    SparkMainTabPreviewContainer()
}
