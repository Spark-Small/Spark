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
    let messagesRepository: any MessagesRepository
    let activityFeedRepository: any ActivityFeedRepository
    let activityBrowseRepository: any ActivityBrowseRepository
    let likesFeedRepository: any LikesFeedRepository
    let searchRepository: any SearchRepository
    let communityPostsRepository: any CommunityPostsRepository
    let trustRepository: any TrustRepository
    let paywallRouter: PaywallRouter
    let blockedActivityHostsStore: BlockedActivityHostsStore
    let discoverMediaImageCache: DiscoverMediaImageCache

    @State private var messagesViewModel: MessagesViewModel?
    @State private var profileViewModel: ProfileViewModel?
    @State private var searchQuery: String = ""

    public init(
        router: AppRouter,
        authViewModel: AuthViewModel,
        entitlementManager: EntitlementManager,
        messagesRepository: any MessagesRepository,
        activityFeedRepository: any ActivityFeedRepository,
        activityBrowseRepository: any ActivityBrowseRepository,
        likesFeedRepository: any LikesFeedRepository,
        searchRepository: any SearchRepository,
        communityPostsRepository: any CommunityPostsRepository,
        trustRepository: any TrustRepository,
        paywallRouter: PaywallRouter,
        blockedActivityHostsStore: BlockedActivityHostsStore = BlockedActivityHostsStore(),
        discoverMediaImageCache: DiscoverMediaImageCache = DiscoverMediaImageCache()
    ) {
        self.router = router
        self.authViewModel = authViewModel
        self.entitlementManager = entitlementManager
        self.messagesRepository = messagesRepository
        self.activityFeedRepository = activityFeedRepository
        self.activityBrowseRepository = activityBrowseRepository
        self.likesFeedRepository = likesFeedRepository
        self.searchRepository = searchRepository
        self.communityPostsRepository = communityPostsRepository
        self.trustRepository = trustRepository
        self.paywallRouter = paywallRouter
        self.blockedActivityHostsStore = blockedActivityHostsStore
        self.discoverMediaImageCache = discoverMediaImageCache
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
            try? await likesFeedRepository.syncPremiumEntitlement(isActive: isActive)
        }
    }

    @ViewBuilder
    var profileTab: some View {
        if let profileViewModel {
            ProfileRootView(
                viewModel: profileViewModel,
                trustRepository: trustRepository,
                searchRepository: searchRepository,
                onSelectSearchResult: handleSearchResult,
                onSignOut: {
                    Task {
                        await authViewModel.signOutTapped()
                        router.resetAfterSignOut()
                    }
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
            messagesRepository: messagesRepository,
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
            messagesViewModel = MessagesViewModel(repository: messagesRepository)
        }
    }

    private func ensureProfileViewModel() {
        if profileViewModel == nil {
            profileViewModel = ProfileViewModel(trustRepository: trustRepository)
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
