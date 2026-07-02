// Module: SparkAppShell — Shared tab roots (without tab chrome).

import SparkActivity
import SparkBuddy
import SparkCommunity
import SparkMessages
import SparkPayments
import SparkProfile
import SparkSearch
import SwiftUI

extension SparkMainTabView {
    var activityTabRoot: some View {
        ActivityRootView(
            coordinator: tabDependencies.activityCoordinator,
            pendingActivityID: $router.pendingActivityID,
            pendingActivityDetailContext: $router.pendingActivityDetailContext,
            pendingCreateActivityDraft: $router.pendingCreateActivityDraft,
            pendingBrowseJoinActivityID: $router.pendingBrowseJoinActivityID,
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
                ActivityFeedPremiumLock.isRowLocked(
                    at: index,
                    isPaywallEnabled: SparkFeatureFlags.isPremiumPaywallEnabled,
                    hasFullFeedAccess: entitlementManager.canAccess(.fullActivityFeed)
                )
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
            fetchBuddyRecommendation: { category in
                guard let recommendation = await tabDependencies.orchestrator
                    .fetchRecommendedBuddy(forActivityCategory: category) else {
                    return nil
                }
                return (
                    listingID: recommendation.listingID,
                    title: recommendation.title,
                    subtitle: recommendation.subtitle
                )
            },
            onOpenBuddyListing: { listingID in
                router.openBuddyDetail(listingID: listingID)
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
            },
            isAuthenticated: authViewModel.isAuthenticated,
            onSignInRequired: { router.presentAuthRequired() },
            onSignInRequiredForActivity: { router.requireSignInForActivity(activityID: $0) },
            onSignInRequiredForBrowseJoin: { router.requireSignInForBrowseJoin(activityID: $0) },
            onSignInRequiredForCreate: { router.requireSignInForCreateActivity(draft: $0) },
            onOpenHostMessages: { userID in
                router.openConversation(threadID: SparkMainTabRouting.directThreadID(for: userID))
            },
            tabChrome: activityTabChrome,
            isActivityTabSelected: router.selectedTab == .activity
        )
    }

    var communityTabRoot: some View {
        CommunityRootView(
            coordinator: tabDependencies.communityCoordinator,
            pendingCommunityPostID: $router.pendingCommunityPostID,
            pendingRecapActivityID: $router.pendingCommunityRecapActivityID,
            tabChrome: communityTabChrome,
            isAuthenticated: authViewModel.isAuthenticated,
            onSignInRequired: { router.requireSignInForCommunityCompose() },
            fetchActivityShareContext: { activityID in
                await tabDependencies.orchestrator.fetchActivityShareContext(activityID: activityID)
            },
            onLikePerson: { _ in },
            onOpenLinkedActivity: { activityID in
                router.openActivityDetail(activityID: activityID)
            }
        )
    }

    var buddyTabRoot: some View {
        BuddyRootView(
            coordinator: tabDependencies.buddyCoordinator,
            pendingBuddyListingID: $router.pendingBuddyListingID,
            onOpenMessages: { userID in
                router.openConversation(threadID: SparkMainTabRouting.directThreadID(for: userID))
            },
            fetchRecommendedActivity: {
                await tabDependencies.orchestrator.fetchRecommendedActivity()
            },
            onOpenActivity: { activityID in
                router.openActivityDetail(activityID: activityID)
            }
        )
    }

    @ViewBuilder
    var profileTabRoot: some View {
        if authViewModel.isAuthenticated {
            if let profileViewModel {
                ProfileRootView(
                    viewModel: profileViewModel,
                    profileCoordinator: tabDependencies.profileCoordinator,
                    isSearchPresented: $isProfileSearchPresented,
                    searchViewModel: searchViewModel,
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
                    },
                    onOpenSearch: {
                        ensureSearchViewModel()
                        isProfileSearchPresented = true
                    },
                    buddyCoordinator: tabDependencies.buddyCoordinator
                )
            } else {
                ProgressView()
                    .task { ensureProfileViewModel() }
            }
        } else {
            GuestProfilePromptView(onSignIn: { router.presentAuthRequired() })
        }
    }

    func ensureSearchViewModel() {
        guard searchViewModel == nil else { return }
        searchViewModel = tabDependencies.profileCoordinator
            .makeSearchCoordinator()
            .makeViewModel(initialQuery: searchQuery)
    }

    func applyPendingSearchQuery(_ query: String) {
        searchQuery = query
        ensureSearchViewModel()
        searchViewModel?.query = query
        router.selectedTab = .profile
        isProfileSearchPresented = true
        router.pendingSearchQuery = nil
    }

    func presentCreateActivity(draft: CreateActivityDraft? = nil) {
        router.selectedTab = .activity
        let resolved = draft ?? CreateActivityDraft()
        if authViewModel.isAuthenticated {
            router.pendingCreateActivityDraft = resolved
        } else {
            router.requireSignInForCreateActivity(draft: resolved)
        }
    }
}
