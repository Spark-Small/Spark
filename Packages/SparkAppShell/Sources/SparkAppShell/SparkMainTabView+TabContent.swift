// Module: SparkAppShell — TabView children for SparkMainTabView.

import SparkActivity
import SparkCommunity
import SparkCore
import SparkMessages
import SparkPayments
import SparkProfile
import SwiftUI

extension SparkMainTabView {
    @ViewBuilder
    var tabContent: some View {
        CommunityRootView(
            coordinator: tabDependencies.communityCoordinator,
            pendingCommunityPostID: $router.pendingCommunityPostID,
            pendingRecapActivityID: $router.pendingCommunityRecapActivityID,
            fetchActivityShareContext: { activityID in
                await tabDependencies.orchestrator.fetchActivityShareContext(activityID: activityID)
            },
            onLikePerson: { _ in },
            onOpenLinkedActivity: { activityID in
                router.openActivityDetail(activityID: activityID)
            },
            onOpenUserProfile: { userID in
                presentedUserContext = UserContextPresentation(userID: userID)
            }
        )
        .tabItem { tabLabel(for: .community) }
        .tag(SparkTab.community)

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
            isItemLocked: { _ in false },
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
            },
            onOpenUserProfile: { userID in
                presentedUserContext = UserContextPresentation(userID: userID)
            },
            canAccessHostTools: {
                !SparkFeatureFlags.isPremiumPaywallEnabled
                    || entitlementManager.canAccess(.hostTools)
            },
            onHostToolsLocked: {
                paywallRouter.presentPaywall(placement: .activity)
            },
            inviteCandidates: {
                ActivityInviteCandidateBuilder.from(messagesViewModel: messagesViewModel)
            },
        )
        .tabItem { tabLabel(for: .activity) }
        .tag(SparkTab.activity)

        messagesTabWithBadge
            .tabItem { tabLabel(for: .messages) }
            .tag(SparkTab.messages)

        profileTab
    }
}
