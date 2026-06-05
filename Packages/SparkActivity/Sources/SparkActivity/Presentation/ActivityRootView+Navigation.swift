// Module: SparkActivity — Activity root navigation helpers.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    func activityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            activityID: activityID,
            repository: repository,
            context: .inbox,
            onRSVPCompleted: onRSVPCompleted,
            onOpenGroupChat: onOpenGroupChat,
            onActivityUpdated: { _ in await viewModel.load() },
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap
        )
    }

    func externalActivityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            activityID: activityID,
            repository: repository,
            context: .externalEntry,
            onRSVPCompleted: onRSVPCompleted,
            onOpenGroupChat: onOpenGroupChat,
            onActivityUpdated: { _ in await viewModel.load() },
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap
        )
    }

    @ViewBuilder
    func activityRow(for item: ActivityItem, at index: Int) -> some View {
        let locked = isItemLocked(index)
        if locked, let onLockedItemTap {
            Button(action: onLockedItemTap) {
                ActivityInboxListRow(item: item, isLocked: true)
            }
            .buttonStyle(.plain)
            .accessibilityHint(
                String(
                    localized: "activity.row.premium.hint",
                    defaultValue: "订阅后可查看",
                    comment: "Locked activity row"
                )
            )
        } else {
            NavigationLink(value: item) {
                ActivityInboxListRow(item: item, isLocked: false)
            }
            .accessibilityHint(
                String(
                    localized: "activity.row.openDetail.hint",
                    defaultValue: "查看活动邀请详情",
                    comment: "Activity row opens detail"
                )
            )
        }
    }

    func openPendingActivity(activityID: String) async {
        navigationPath.append(activityID)
        pendingActivityID = nil
        if viewModel.loadState == .idle {
            await viewModel.load()
        }
    }
}
