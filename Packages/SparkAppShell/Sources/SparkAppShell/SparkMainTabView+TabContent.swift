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
            },
            inviteCandidates: {
                ActivityInviteCandidateBuilder.from(messagesViewModel: messagesViewModel)
            },
            actionItemsInset: { filter in
                guard filter.showsInboxActionItems,
                      let messagesViewModel,
                      !messagesViewModel.actionItems.isEmpty
                else {
                    return AnyView(EmptyView())
                }

                return AnyView(
                    InboxActionItemsListSection(
                        items: messagesViewModel.actionItems,
                        onInviteAccept: { invite in
                            Task { await messagesViewModel.handleInviteResponse(invite: invite, accept: true) }
                        },
                        onInviteDecline: { invite in
                            Task { await messagesViewModel.handleInviteResponse(invite: invite, accept: false) }
                        },
                        onOpenActivity: { activityID in
                            router.openActivityDetail(activityID: activityID)
                        },
                        onDismiss: { item in
                            Task { await messagesViewModel.dismissActionItem(id: item.id) }
                        }
                    )
                )
            },
            requestActivityIDs: { filter in
                guard filter == .pendingReply, let messagesViewModel else { return [] }
                return messagesViewModel.actionItems.coveredActivityIDs
            }
        )
        .tabItem { tabLabel(for: .activity) }
        .tag(SparkTab.activity)

        messagesTabWithBadge
            .tabItem { tabLabel(for: .messages) }
            .tag(SparkTab.messages)

        profileTab
    }
}
