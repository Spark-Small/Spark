// Module: SparkAppShell — Five-tab primary interface (Nexus + W0).

import SparkActivity
import SparkAuth
import SparkCommunity
import SparkCore
import SparkMessages
import SparkNotifications
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

    @State var messagesViewModel: MessagesViewModel?
    @State private var peerDisplayNameStore: PeerDisplayNameStore?
    @State private var profileViewModel: ProfileViewModel?
    @State private var searchQuery: String = ""
    @State private var showPushPermissionGuide = false
    @State private var showDeepLinkFallback = false

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
            if !SparkPushPermissionPreferences.hasSeenGuide {
                showPushPermissionGuide = true
            }
        }
        .onChange(of: router.selectedTab) { _, tab in
            guard tab == .messages || tab == .activity else { return }
            Task { await messagesViewModel?.load() }
        }
        .onChange(of: router.pendingUnrecognizedURL) { _, url in
            showDeepLinkFallback = url != nil
        }
        .fullScreenCover(isPresented: $showPushPermissionGuide) {
            PushNotificationPermissionGuideView(
                onContinue: { showPushPermissionGuide = false },
                onSkip: { showPushPermissionGuide = false }
            )
        }
        .sheet(isPresented: $showDeepLinkFallback) {
            if let url = router.pendingUnrecognizedURL {
                UniversalLinkFallbackView(url: url) {
                    router.clearPendingUnrecognizedURL()
                    showDeepLinkFallback = false
                }
            }
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
                },
                onOpenPersonMessages: { userID in
                    router.openConversation(threadID: SparkMainTabRouting.directThreadID(for: userID))
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
        Group {
            if let messagesViewModel, let peerDisplayNameStore {
                SparkMainTabMessagesSection(
                    peerDisplayNameStore: peerDisplayNameStore,
                    messagesViewModel: messagesViewModel,
                    pendingConversationThreadID: $router.pendingConversationThreadID,
                    onOpenActivity: { router.openActivityDetail(activityID: $0) },
                    onProposeMeetup: { peerName in
                        router.openCreateActivity(draft: .matchCoffee(peerName: peerName))
                    },
                    onOpenActivityTab: { router.selectedTab = .activity },
                    onScannedPayload: { payload in
                        guard let url = URL(string: payload) else { return }
                        router.handle(url: url, isAuthenticated: authViewModel.isAuthenticated)
                    }
                )
            } else {
                ProgressView()
                    .task { ensureMessagesTabState() }
            }
        }
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

    private func ensureMessagesTabState() {
        if peerDisplayNameStore == nil {
            peerDisplayNameStore = PeerDisplayNameStore(storage: tabDependencies.peerDisplayNameStorage)
        }
        if messagesViewModel == nil, let peerDisplayNameStore {
            messagesViewModel = tabDependencies.messagesCoordinator.makeInboxViewModel(
                peerDisplayNameStore: peerDisplayNameStore
            )
        }
    }

    private func ensureMessagesViewModel() {
        ensureMessagesTabState()
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
