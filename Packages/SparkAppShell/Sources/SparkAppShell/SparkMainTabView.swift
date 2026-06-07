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
    private var tabContent: some View {
        LikesRootView(
            repository: likesFeedRepository,
            discoverMediaImageCache: discoverMediaImageCache,
            pendingInbound: $router.pendingLikesInbound,
            onOpenMatchConversation: { threadID, peerDisplayName, initialMessage in
                let peerUserID = SparkMainTabRouting.peerUserID(fromDirectThreadID: threadID)
                let resolvedThread = try? await messagesRepository.ensureDirectMessageThread(
                    peerUserID: peerUserID,
                    peerDisplayName: peerDisplayName
                )
                let thread = (resolvedThread ?? MessageThreadID(threadID)).rawValue
                if let initialMessage, !initialMessage.isEmpty {
                    _ = try? await messagesRepository.sendMessage(
                        threadID: MessageThreadID(thread),
                        body: initialMessage
                    )
                }
                await MainActor.run {
                    router.openConversation(threadID: thread)
                }
            },
            onOpenSharedActivity: { activityID in
                Task { @MainActor in
                    router.openActivityDetail(activityID: activityID)
                }
            },
            fetchRecommendedActivity: {
                guard let page = try? await activityBrowseRepository.fetchBrowse(
                    query: ActivityBrowseQuery(startsBefore: Date().addingTimeInterval(604_800))
                ),
                    let item = page.items.first else {
                    return nil
                }
                return (item.id, item.title)
            },
            onCreateMatchCoffee: { peerName in
                IntegrationTelemetry.matchToActivityIntent(source: "match_coffee")
                router.openCreateActivity(draft: CreateActivityDraft.matchCoffee(peerName: peerName))
            },
            isInboundItemBlurred: { item in
                SparkFeatureFlags.isPremiumInboundBlurEnabled
                    && SparkFeatureFlags.isPremiumPaywallEnabled
                    && !entitlementManager.canAccess(.inboundLikes)
                    && !item.isVisible
            },
            onInboundPaywall: {
                paywallRouter.presentPaywall(placement: .likes)
            },
            onSparkPaywall: {
                paywallRouter.presentPaywall(placement: .likes)
            }
        )
        .tabItem { tabLabel(for: .likes) }
        .tag(SparkTab.likes)

        CommunityRootView(
            repository: communityPostsRepository,
            pendingCommunityPostID: $router.pendingCommunityPostID,
            pendingRecapActivityID: $router.pendingCommunityRecapActivityID,
            fetchActivityRecap: { activityID in
                guard let detail = try? await activityFeedRepository.fetchActivity(id: activityID) else {
                    return nil
                }
                return (detail.title, detail.scheduleLine)
            },
            onOpenSearch: {
                router.selectedTab = .profile
            },
            onOpenLikesDiscover: {
                router.selectedTab = .likes
            },
            onLikePerson: { userID in
                Task {
                    _ = try? await likesFeedRepository.submitLike(
                        SendLikeRequest(userID: UserID(userID), intensity: .like)
                    )
                }
            },
            onOpenLinkedActivity: { activityID in
                router.openActivityDetail(activityID: activityID)
            }
        )
        .tabItem { tabLabel(for: .community) }
        .tag(SparkTab.community)

        messagesTabWithBadge
            .tabItem { tabLabel(for: .messages) }
            .tag(SparkTab.messages)

        ActivityRootView(
            repository: activityFeedRepository,
            blockedHostsStore: blockedActivityHostsStore,
            browseRepository: activityBrowseRepository,
            pendingActivityID: $router.pendingActivityID,
            pendingCreateActivityDraft: $router.pendingCreateActivityDraft,
            onRSVPCompleted: { detail in
                await activityGroupChatCoordinator.onRSVPCompleted(detail)
                await ActivityLocalReminderScheduler.syncReminders(for: detail)
            },
            onOpenGroupChat: { detail in
                await activityGroupChatCoordinator.openGroupChat(for: detail)
            },
            onActivityCreated: { detail in
                await activityGroupChatCoordinator.onRSVPCompleted(detail)
                await ActivityLocalReminderScheduler.syncReminders(for: detail)
            },
            isItemLocked: { index in
                SparkFeatureFlags.isPremiumPaywallEnabled
                    && !entitlementManager.canAccess(.fullActivityFeed)
                    && index > 0
            },
            onLockedItemTap: {
                paywallRouter.presentPaywall(placement: .activity)
            },
            onHostAnnouncePosted: { detail, message in
                await activityGroupChatCoordinator.postHostAnnounce(for: detail, message: message)
            },
            onActivityRescheduled: { detail in
                await activityGroupChatCoordinator.postRescheduleNotice(for: detail)
            },
            onCommunityRecap: { detail in
                router.openCommunityRecap(activityID: detail.id)
            }
        )
        .tabItem { tabLabel(for: .activity) }
        .tag(SparkTab.activity)

        profileTab
    }

    @ViewBuilder
    private var profileTab: some View {
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

    private var activityGroupChatCoordinator: ActivityGroupChatCoordinator {
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
    private var messagesTabWithBadge: some View {
        if let badge = messagesViewModel?.tabBadge {
            messagesTab.badge(badge)
        } else {
            messagesTab
        }
    }

    private var messagesTab: some View {
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

    private func tabLabel(for tab: SparkTab) -> some View {
        let isSelected = router.selectedTab == tab
        return Label(
            tab.title,
            systemImage: isSelected ? tab.selectedSystemImage : tab.systemImage
        )
    }
}
