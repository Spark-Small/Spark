// Module: SparkAppShell — Primary tab interface (Nexus + W0).

import SparkActivity
import SparkAuth
import SparkBuddy
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
    @State var profileViewModel: ProfileViewModel?
    @State var isProfileSearchPresented = false
    @State var searchQuery: String = ""
    @State var searchViewModel: SearchViewModel?
    @State private var showPushPermissionGuide = false
    @State private var showDeepLinkFallback = false
    @State var activityTabChrome = ActivityTabChrome()
    @State var communityTabChrome = CommunityTabChrome()

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
        Group {
            if #available(iOS 18.0, *) {
                modernTabView
            } else {
                legacyTabView
            }
        }
        .onChange(of: authViewModel.isAuthenticated) { _, isAuthenticated in
            if isAuthenticated {
                if !SparkPushPermissionPreferences.hasSeenGuide {
                    showPushPermissionGuide = true
                }
            } else {
                searchQuery = ""
                searchViewModel = nil
                isProfileSearchPresented = false
                router.resetAfterSignOut()
            }
        }
        .onChange(of: router.pendingSearchQuery) { _, query in
            if let query {
                applyPendingSearchQuery(query)
            }
        }
        .sheet(item: $router.globalSheet) { presentation in
            GlobalSheetContent(
                presentation: presentation,
                authViewModel: authViewModel
            ) {
                router.cancelAuthPresentation()
            }
        }
        .fullScreenCover(item: $router.globalFullScreenCover) { presentation in
            GlobalFullScreenContent(
                presentation: presentation,
                authViewModel: authViewModel,
                entitlementManager: entitlementManager
            ) {
                router.dismissGlobalPresentation()
            }
        }
        .onAppear {
            ensureMessagesViewModel()
            ensureProfileViewModel()
            activityTabChrome.navigation.isActivityTabSelected = router.selectedTab == .activity
            activityTabChrome.reconcile()
            if let query = router.pendingSearchQuery {
                applyPendingSearchQuery(query)
            }
            if authViewModel.isAuthenticated, !SparkPushPermissionPreferences.hasSeenGuide {
                showPushPermissionGuide = true
            }
        }
        .onChange(of: router.selectedTab) { _, tab in
            activityTabChrome.navigation.isActivityTabSelected = tab == .activity
            activityTabChrome.reconcile()
            if tab != .community {
                communityTabChrome.sync(tabSelected: false)
            }
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
                        presentCreateActivity(draft: .matchCoffee(peerName: peerName))
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

    var tabSelection: Binding<SparkTab> {
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

    func ensureProfileViewModel() {
        if profileViewModel == nil {
            profileViewModel = tabDependencies.profileCoordinator.makeProfileViewModel()
        }
    }

    func handleSearchResult(_ item: SearchResultItem) {
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
