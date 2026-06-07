//
//  ContentView.swift
//  Spark
//

import SparkAppShell
import SparkAuth
import SparkDesignSystem
import SwiftUI

/// Application root view — auth guard and tab shell via `SparkAppShell`.
struct ContentView: View {
    private let appDelegate: SparkAppDelegate?
    private let dependencies: AppDependencies
    @State private var authViewModel: AuthViewModel
    @State private var router: AppRouter
    @State private var paywallRouter: PaywallRouter

    init(dependencies: AppDependencies, appDelegate: SparkAppDelegate? = nil) {
        self.appDelegate = appDelegate
        self.dependencies = dependencies
        let router = AppRouter()
        _authViewModel = State(initialValue: dependencies.authCoordinator.makeAuthViewModel())
        _router = State(initialValue: router)
        _paywallRouter = State(initialValue: PaywallRouter(appRouter: router))
    }

    var body: some View {
        SparkRootView(
            authViewModel: authViewModel,
            router: router,
            entitlementManager: dependencies.entitlementManager,
            tabDependencies: dependencies.tabDependencies,
            paywallRouter: paywallRouter
        )
        .environment(router)
        .environment(dependencies.entitlementManager)
        .environment(\.remoteImageCache, dependencies.remoteImageCache)
        .onOpenURL { url in
            router.handle(url: url, isAuthenticated: authViewModel.isAuthenticated)
        }
        .onAppear {
            appDelegate?.router = router
            appDelegate?.deviceTokenUploader = dependencies.deviceTokenUploader
        }
    }
}

#Preview {
    let dependencies = CompositionRoot.bootstrap()
    return ContentView(dependencies: dependencies)
        .environment(\.appDependencies, dependencies)
}
