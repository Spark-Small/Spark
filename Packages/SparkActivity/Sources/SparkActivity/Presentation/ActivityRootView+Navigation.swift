// Module: SparkActivity — Activity root navigation helpers.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    func activityDetailView(activityID: String, context: ActivityDetailContext = .inbox) -> some View {
        activityDetailChrome(
            ActivityDetailView(
                viewModel: coordinator.makeDetailViewModel(
                    activityID: activityID,
                    context: context,
                    onRSVPCompleted: onRSVPCompleted,
                    onActivityUpdated: { _ in await viewModel.load() }
                ),
                coordinator: coordinator,
                inviteCandidates: inviteCandidates,
                onOpenGroupChat: onOpenGroupChat,
                onHostAnnouncePosted: onHostAnnouncePosted,
                onActivityRescheduled: onActivityRescheduled,
                onCommunityRecap: onCommunityRecap,
                onOpenUserProfile: onOpenUserProfile,
                canAccessHostTools: canAccessHostTools(),
                onHostToolsLocked: onHostToolsLocked
            )
        )
    }

    func externalActivityDetailView(activityID: String) -> some View {
        activityDetailChrome(
            ActivityDetailView(
                viewModel: coordinator.makeDetailViewModel(
                    activityID: activityID,
                    context: .externalEntry,
                    onRSVPCompleted: onRSVPCompleted,
                    onActivityUpdated: { _ in await viewModel.load() }
                ),
                coordinator: coordinator,
                inviteCandidates: inviteCandidates,
                onOpenGroupChat: onOpenGroupChat,
                onHostAnnouncePosted: onHostAnnouncePosted,
                onActivityRescheduled: onActivityRescheduled,
                onCommunityRecap: onCommunityRecap,
                onOpenUserProfile: onOpenUserProfile,
                canAccessHostTools: canAccessHostTools(),
                onHostToolsLocked: onHostToolsLocked
            )
        )
    }

    private func activityDetailChrome<Content: View>(_ content: Content) -> some View {
        content.environment(activityFavoriteStore)
    }

    @ViewBuilder
    func activityRow(for item: ActivityItem, at index: Int) -> some View {
        let locked = isItemLocked(index)
        if locked, let onLockedItemTap {
            Button(action: onLockedItemTap) {
                ActivityInboxListRow(item: item, isLocked: true)
            }
            .buttonStyle(.sparkPressable)
            .sparkFlatTabListRow()
            .accessibilityHint(
                String(
                    localized: "activity.row.premium.hint",
                    defaultValue: "订阅后可查看",
                    comment: "Locked activity row"
                )
            )
        } else {
            // REASONING: ShareLink + favorite live inside the row hero; NavigationLink swallows row taps.
            ActivityInboxListRow(item: item, isLocked: false)
                .contentShape(Rectangle())
                .onTapGesture {
                    openActivity(item.id, context: .inbox)
                }
                .sparkFlatTabListRow()
                .accessibilityAddTraits(.isButton)
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

    func openActivity(_ activityID: String, context: ActivityDetailContext? = nil) {
        let resolved = context ?? (selectedInboxSegment == .discover ? .discover : .inbox)
        let route = ActivityDetailRoute(activityID: activityID, context: resolved)
        if usesSplitLayout {
            selectedActivityID = activityID
            selectedDetailRoute = route
        } else {
            navigationPath.append(route)
        }
    }
}
