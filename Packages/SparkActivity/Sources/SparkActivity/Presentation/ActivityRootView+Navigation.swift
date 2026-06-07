// Module: SparkActivity — Activity root navigation helpers.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    func activityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            viewModel: coordinator.makeDetailViewModel(
                activityID: activityID,
                context: .inbox,
                onRSVPCompleted: onRSVPCompleted,
                onActivityUpdated: { _ in await viewModel.load() }
            ),
            coordinator: coordinator,
            onOpenGroupChat: onOpenGroupChat,
            onHostAnnouncePosted: onHostAnnouncePosted,
            onActivityRescheduled: onActivityRescheduled,
            onCommunityRecap: onCommunityRecap
        )
    }

    func externalActivityDetailView(activityID: String) -> some View {
        ActivityDetailView(
            viewModel: coordinator.makeDetailViewModel(
                activityID: activityID,
                context: .externalEntry,
                onRSVPCompleted: onRSVPCompleted,
                onActivityUpdated: { _ in await viewModel.load() }
            ),
            coordinator: coordinator,
            onOpenGroupChat: onOpenGroupChat,
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
            .buttonStyle(.sparkPressable)
            .accessibilityHint(
                String(
                    localized: "activity.row.premium.hint",
                    defaultValue: "订阅后可查看",
                    comment: "Locked activity row"
                )
            )
        } else if usesSplitLayout {
            ActivityInboxListRow(item: item, isLocked: false)
                .accessibilityHint(
                    String(
                        localized: "activity.row.openDetail.hint",
                        defaultValue: "查看活动邀请详情",
                        comment: "Activity row opens detail"
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
        openActivity(activityID)
        pendingActivityID = nil
        if viewModel.loadState == .idle {
            await viewModel.load()
        }
    }

    func openActivity(_ activityID: String) {
        if usesSplitLayout {
            selectedActivityID = activityID
        } else {
            navigationPath.append(activityID)
        }
    }
}
