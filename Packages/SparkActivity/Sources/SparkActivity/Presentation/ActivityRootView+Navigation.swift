// Module: SparkActivity — Activity root navigation helpers.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    func activityDetailView(activityID: String, usesTabAccessory: Bool = true) -> some View {
        let context: ActivityDetailContext = {
            if externalEntryActivityID == activityID {
                return .externalEntry
            }
            return selectedHomeSegment == .discover ? .discover : .inbox
        }()
        return ActivityDetailView(
            activityID: activityID,
            coordinator: coordinator,
            context: context,
            tabChrome: usesTabAccessory ? tabChrome : nil,
            isActivityTabSelected: isActivityTabSelected,
            isAuthenticated: isAuthenticated,
            onSignInRequired: { onSignInRequiredForActivity?(activityID) },
            inviteCandidates: inviteCandidates,
            onRSVPCompleted: onRSVPCompleted,
            onOpenGroupChat: onOpenGroupChat,
            onActivityUpdated: { _ in await reloadVisibleCatalogs() },
            onHostBlocked: { await reloadVisibleCatalogs() },
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap,
            fetchBuddyRecommendation: fetchBuddyRecommendation,
            onOpenBuddyListing: onOpenBuddyListing
        )
    }

    @ViewBuilder
    func activityRow(for item: ActivityItem, at index: Int) -> some View {
        ActivityInboxListRow.listRow(
            item: item,
            at: index,
            isItemLocked: isItemLocked,
            onLockedItemTap: onLockedItemTap
        ) {
            openActivity(item.id)
        }
    }

    func openPendingActivity(activityID: String) async {
        let entryContext = pendingActivityDetailContext
        pendingActivityDetailContext = nil
        openActivity(activityID, entryContext: entryContext)
        pendingActivityID = nil
        if isAuthenticated, viewModel.loadState == .idle {
            await viewModel.load()
        }
    }

    func openActivity(_ activityID: String, entryContext: ActivityDetailContext? = nil) {
        switch entryContext {
        case .externalEntry:
            externalEntryActivityID = activityID
        case .discover, .inbox, .none:
            externalEntryActivityID = nil
        }
        if showMyActivities {
            myActivitiesNavigationPath.append(activityID)
            return
        }
        navigationPath.append(activityID)
    }

    func openHostProfile(hostID: String, displayName: String) {
        hostProfileRoute = ActivityHostProfileRoute(hostID: hostID, displayName: displayName)
    }
}
