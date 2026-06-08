//
//  ContentView.swift
//  Spark
//

import SparkAppShell
import SparkAuth
import SparkPayments
import SwiftUI

/// Application root view — auth guard and tab shell via `SparkAppShell`.
struct ContentView: View {
    private let appDelegate: SparkAppDelegate?
    @State private var authViewModel: AuthViewModel
    @State private var router: AppRouter
    @State private var paywallRouter: PaywallRouter

    @MainActor
    init(appDelegate: SparkAppDelegate? = nil) {
        self.appDelegate = appDelegate
        CompositionRoot.bootstrapIfNeeded()
        let dependencies = CompositionRoot.dependencies
        let router = AppRouter()
        let cnCoordinators = LiveCNAuthCoordinatorsFactory.make(configuration: dependencies.apiConfiguration)
        _authViewModel = State(
            initialValue: AuthViewModel(
                authService: dependencies.authService,
                cnCoordinators: cnCoordinators
            )
        )
        _router = State(initialValue: router)
        _paywallRouter = State(initialValue: PaywallRouter(appRouter: router))
    }

    var body: some View {
        SparkRootView(
            authViewModel: authViewModel,
            router: router,
            entitlementManager: CompositionRoot.dependencies.entitlementManager,
            messagesRepository: CompositionRoot.dependencies.messagesRepository,
            activityFeedRepository: CompositionRoot.dependencies.activityFeedRepository,
            activityBrowseRepository: CompositionRoot.dependencies.activityBrowseRepository,
            likesFeedRepository: CompositionRoot.dependencies.likesFeedRepository,
            profileRepository: CompositionRoot.dependencies.profileRepository,
            searchRepository: CompositionRoot.dependencies.searchRepository,
            communityPostsRepository: CompositionRoot.dependencies.communityPostsRepository,
            paywallRouter: paywallRouter,
            blockedActivityHostsStore: CompositionRoot.dependencies.blockedActivityHostsStore,
            discoverMediaImageCache: CompositionRoot.dependencies.discoverMediaImageCache
        )
        .environment(router)
        .environment(CompositionRoot.dependencies.entitlementManager)
        .onOpenURL { url in
            if authViewModel.handleOpenURL(url) { return }
            if CompositionRoot.dependencies.entitlementManager.handleOpenURL(url) { return }
            router.handle(url: url, isAuthenticated: authViewModel.isAuthenticated)
        }
        .onAppear {
            appDelegate?.router = router
            appDelegate?.authViewModel = authViewModel
            appDelegate?.deviceTokenUploader = CompositionRoot.dependencies.deviceTokenUploader
        }
    }
}

#Preview {
    ContentView()
}
