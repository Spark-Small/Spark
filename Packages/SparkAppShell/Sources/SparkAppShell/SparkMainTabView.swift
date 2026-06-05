// Module: SparkAppShell — Five-tab primary interface.

import SparkActivity
import SparkAuth
import SparkCommunity
import SparkLikes
import SparkMessages
import SparkPayments
import SparkSearch
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
    let paywallRouter: PaywallRouter

    @State private var messagesViewModel: MessagesViewModel?
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
        paywallRouter: PaywallRouter
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
            if let query = router.pendingSearchQuery {
                searchQuery = query
                router.pendingSearchQuery = nil
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        LikesRootView(
            repository: likesFeedRepository,
            pendingInbound: $router.pendingLikesInbound,
            onOpenMatchConversation: { threadID, peerDisplayName, initialMessage in
            let peerUserID = Self.peerUserID(fromDirectThreadID: threadID)
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
            isInboundItemBlurred: { item in
                SparkFeatureFlags.isPremiumInboundBlurEnabled
                    && SparkFeatureFlags.isPremiumPaywallEnabled
                    && !entitlementManager.canAccess(.inboundLikes)
                    && !item.isVisible
            },
            onInboundPaywall: {
                paywallRouter.presentPaywall(placement: .likes)
            }
        )
        .tabItem { Label(SparkTab.likes.title, systemImage: SparkTab.likes.systemImage) }
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
            }
        )
        .tabItem { Label(SparkTab.community.title, systemImage: SparkTab.community.systemImage) }
        .tag(SparkTab.community)

        messagesTab
            .tabItem { Label(SparkTab.messages.title, systemImage: SparkTab.messages.systemImage) }
            .tag(SparkTab.messages)

        ActivityRootView(
            repository: activityFeedRepository,
            browseRepository: activityBrowseRepository,
            pendingActivityID: $router.pendingActivityID,
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
        .toolbar { accountToolbarIfNeeded }
        .tabItem { Label(SparkTab.activity.title, systemImage: SparkTab.activity.systemImage) }
        .tag(SparkTab.activity)

        SearchRootView(
            repository: searchRepository,
            initialQuery: searchQuery,
            onSelectResult: handleSearchResult
        )
        .id(searchQuery)
        .tabItem { Label(SparkTab.search.title, systemImage: SparkTab.search.systemImage) }
        .tag(SparkTab.search)
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
    private var messagesTab: some View {
        if let messagesViewModel {
            MessagesRootView(
                viewModel: messagesViewModel,
                pendingConversationThreadID: $router.pendingConversationThreadID
            )
        } else {
            ProgressView()
                .task { ensureMessagesViewModel() }
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

    private func ensureMessagesViewModel() {
        if messagesViewModel == nil {
            messagesViewModel = MessagesViewModel(repository: messagesRepository)
        }
    }

    private func handleSearchResult(_ item: SearchResultItem) {
        switch item.resultKind {
        case .community:
            router.openCommunityPost(postID: item.id)
        case .activity:
            router.openActivityDetail(activityID: item.id)
        case .person, .none:
            break
        }
    }

    private nonisolated static func peerUserID(fromDirectThreadID threadID: String) -> String {
        let prefix = "th_dm_"
        if threadID.hasPrefix(prefix) {
            return String(threadID.dropFirst(prefix.count))
        }
        return threadID
    }

    @ToolbarContentBuilder
    private var accountToolbarIfNeeded: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if SparkFeatureFlags.isPremiumPaywallEnabled, !entitlementManager.hasPremium {
                Button(
                    String(localized: "paywall.cta", defaultValue: "Premium", comment: "Premium CTA")
                ) {
                    paywallRouter.presentPaywall(placement: .activity)
                }
                .accessibilityLabel(
                    String(localized: "paywall.cta.a11y", defaultValue: "查看订阅", comment: "Premium a11y")
                )
            }

            Button(
                String(localized: "auth.signOut", defaultValue: "退出登录", comment: "Sign out")
            ) {
                Task {
                    await authViewModel.signOutTapped()
                    router.resetAfterSignOut()
                }
            }
        }
    }
}
