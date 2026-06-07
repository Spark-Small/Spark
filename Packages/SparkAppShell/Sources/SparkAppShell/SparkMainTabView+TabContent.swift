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
            coordinator: tabDependencies.likesCoordinator,
            pendingInbound: $router.pendingLikesInbound,
            onOpenMatchConversation: { threadID, peerDisplayName, initialMessage in
                let thread = await tabDependencies.orchestrator.openMatchConversation(
                    threadID: threadID,
                    peerDisplayName: peerDisplayName,
                    initialMessage: initialMessage
                )
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
                await tabDependencies.orchestrator.fetchRecommendedActivity()
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
            coordinator: tabDependencies.communityCoordinator,
            pendingCommunityPostID: $router.pendingCommunityPostID,
            pendingRecapActivityID: $router.pendingCommunityRecapActivityID,
            fetchActivityRecap: { activityID in
                await tabDependencies.orchestrator.fetchActivityRecap(activityID: activityID)
            },
            onOpenSearch: {
                router.selectedTab = .profile
            },
            onOpenLikesDiscover: {
                router.selectedTab = .likes
            },
            onLikePerson: { userID in
                Task {
                    await tabDependencies.orchestrator.submitCommunityLike(userID: userID)
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
            coordinator: tabDependencies.activityCoordinator,
            pendingActivityID: $router.pendingActivityID,
            pendingCreateActivityDraft: $router.pendingCreateActivityDraft,
            onRSVPCompleted: { detail in
                await activityGroupChatCoordinator.onRSVPCompleted(detail)
                await tabDependencies.orchestrator.syncActivityReminders(for: detail)
            },
            onOpenGroupChat: { detail in
                await activityGroupChatCoordinator.openGroupChat(for: detail)
            },
            onActivityCreated: { detail in
                await activityGroupChatCoordinator.onRSVPCompleted(detail)
                await tabDependencies.orchestrator.syncActivityReminders(for: detail)
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
