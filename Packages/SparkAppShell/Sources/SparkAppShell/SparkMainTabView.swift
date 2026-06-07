// Module: SparkAppShell — Five-tab primary interface (Nexus + W0).

import SparkActivity
import SparkAuth
import SparkCommunity
import SparkCore
import SparkLikes
import SparkMessages
import SparkPayments
import SparkProfile
import SparkSearch
import SparkTrust
import SwiftUI

public struct SparkMainTabView: View {
    @Bindable var router: AppRouter
    @Bindable var authViewModel: AuthViewModel
    @Bindable var entitlementManager: EntitlementManager
    let tabDependencies: SparkTabDependencies
    let paywallRouter: PaywallRouter

    @State private var messagesViewModel: MessagesViewModel?
    @State private var profileViewModel: ProfileViewModel?
    @State private var searchQuery: String = ""

    public init(
        router: AppRouter,
        authViewModel: AuthViewModel,
        entitlementManager: EntitlementManager,
        tabDependencies: SparkTabDependencies,
        paywallRouter: PaywallRouter
    ) {
        self.router = router
        self.authViewModel = authViewModel
        self.entitlementManager = entitlementManager
        self.tabDependencies = tabDependencies
        self.paywallRouter = paywallRouter
    }

    public var body: some View {
        TabView(selection: tabSelection) {
            tabContent
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                router.resetAfterSignOut()
            }
        }
        .onChange(of: router.pendingSearchQuery) { _, query in
            if let query {
                searchQuery = query
                router.selectedTab = .profile
                router.pendingSearchQuery = nil
            }
        }
        .sheet(item: $router.globalSheet) { presentation in
            GlobalSheetContent(presentation: presentation) {
                router.dismissGlobalPresentation()
            }
        }
        .fullScreenCover(item: $router.globalFullScreenCover) { presentation in
            GlobalFullScreenContent(
                presentation: presentation,
                entitlementManager: entitlementManager
            ) {
                router.dismissGlobalPresentation()
            }
        }
        .onAppear {
            ensureMessagesViewModel()
            ensureProfileViewModel()
            if let query = router.pendingSearchQuery {
                searchQuery = query
                router.selectedTab = .profile
                router.pendingSearchQuery = nil
            }
            syncPremiumEntitlementToBackend()
        }
        .onChange(of: entitlementManager.hasPremium) { _, _ in
            syncPremiumEntitlementToBackend()
        }
        .onChange(of: router.selectedTab) { _, tab in
            guard tab == .messages else { return }
            Task { await messagesViewModel?.load() }
        }
    }

    private func syncPremiumEntitlementToBackend() {
        guard SparkFeatureFlags.isPremiumInboundBlurEnabled else { return }
        let isActive = entitlementManager.hasPremium
        Task {
            await tabDependencies.orchestrator.syncPremiumEntitlement(isActive: isActive)
        }
    }

    @ViewBuilder
    var profileTab: some View {
        if let profileViewModel {
            ProfileRootView(
                viewModel: profileViewModel,
                profileCoordinator: tabDependencies.profileCoordinator,
                onSelectSearchResult: handleSearchResult,
                onSignOut: {
                    Task {
                        await authViewModel.signOutTapped()
                        router.resetAfterSignOut()
                    }
                },
                onDeleteAccount: {
                    await authViewModel.deleteAccountTapped()
                    router.resetAfterSignOut()
                },
                onOpenPaywall: {
                    paywallRouter.presentPaywall(placement: .activity)
                }
            )
            .tabItem { tabLabel(for: .profile) }
            .tag(SparkTab.profile)
        } else {
            ProgressView()
                .task { ensureProfileViewModel() }
                .tabItem { tabLabel(for: .profile) }
                .tag(SparkTab.profile)
        }
    }

    var activityGroupChatCoordinator: ActivityGroupChatCoordinator {
        ActivityGroupChatCoordinator(
            orchestrator: tabDependencies.orchestrator,
            reloadInbox: {
                ensureMessagesViewModel()
                await messagesViewModel?.load()
            },
            openThread: { threadID in
                router.openConversation(threadID: threadID)
            }
        )
    }

    @ViewBuilder
    var messagesTabWithBadge: some View {
        if let badge = messagesViewModel?.tabBadge {
            messagesTab.badge(badge)
        } else {
            messagesTab
        }
    }

    var messagesTab: some View {
        SparkMainTabMessagesSection(
            messagesViewModel: messagesViewModel,
            pendingConversationThreadID: $router.pendingConversationThreadID,
            onOpenActivity: { router.openActivityDetail(activityID: $0) },
            onOpenLikes: { router.selectedTab = .likes },
            ensureMessagesViewModel: ensureMessagesViewModel
        )
    }

    private var tabSelection: Binding<SparkTab> {
        Binding(
            get: { router.selectedTab },
            set: { newTab in
                let previous = router.selectedTab
                if !router.selectTab(newTab, isAuthenticated: authViewModel.isAuthenticated) {
                    router.selectedTab = previous
                }
            }
        )
    }

    private func ensureMessagesViewModel() {
        if messagesViewModel == nil {
            messagesViewModel = tabDependencies.messagesCoordinator.makeInboxViewModel()
        }
    }

    private func ensureProfileViewModel() {
        if profileViewModel == nil {
            profileViewModel = tabDependencies.profileCoordinator.makeProfileViewModel()
        }
    }

    private func handleSearchResult(_ item: SearchResultItem) {
        SparkMainTabRouting.handleSearchResult(item, router: router)
    }

    func tabLabel(for tab: SparkTab) -> some View {
        let isSelected = router.selectedTab == tab
        return Label(
            tab.title,
            systemImage: isSelected ? tab.selectedSystemImage : tab.systemImage
        )
    }
}

#Preview("Main tabs") {
    SparkMainTabPreviewSupport.tabView(
        authViewModel: SparkMainTabPreviewSupport.makeAuthenticatedViewModel()
    )
}
