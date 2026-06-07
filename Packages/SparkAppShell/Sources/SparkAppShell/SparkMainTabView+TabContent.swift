// Module: SparkAppShell — TabView children for SparkMainTabView.

import SparkActivity
import SparkCommunity
import SparkCore
import SparkLikes
import SparkMessages
import SparkPayments
import SparkProfile
import SwiftUI

extension SparkMainTabView {
    @ViewBuilder
    var tabContent: some View {
        LikesRootView(
            repository: likesFeedRepository,
            discoverMediaImageCache: discoverMediaImageCache,
            preferencesStore: likesPreferencesStore,
            onboardingPreferences: likesOnboardingPreferences,
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
}
