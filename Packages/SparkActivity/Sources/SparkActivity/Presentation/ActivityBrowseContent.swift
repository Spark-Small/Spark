// Module: SparkActivity — Shared browse list body (embedded discover tab).

import SparkDesignSystem
import SwiftUI

struct ActivityBrowseContent: View {
    @Bindable var viewModel: ActivityBrowseViewModel
    let coordinator: ActivityCoordinator
    let isItemLocked: (Int) -> Bool
    let onLockedItemTap: (() -> Void)?
    let isAuthenticated: Bool
    @Binding var pendingBrowseJoinActivityID: String?
    @Binding var joinSheetItem: ActivityItem?
    let onSelectActivity: (String) -> Void
    let onOpenHostProfile: ((String, String) -> Void)?
    let onSignInRequiredForBrowseJoin: ((String) -> Void)?
    let onRSVPCompleted: ((ActivityDetail) async -> Void)?

    var body: some View {
        List {
            switch viewModel.loadState {
            case .idle, .loading:
                ActivityAsyncListLoadingRow(
                    accessibilityLabel: String(
                        localized: "activity.browse.loading.a11y",
                        defaultValue: "正在加载活动",
                        comment: "Browse loading"
                    )
                )
            case .empty:
                browseEmptyState
                    .sparkFlatTabListRow()
            case .failure(let message):
                ActivityAsyncListErrorRow(
                    title: String(
                        localized: "activity.browse.error.title",
                        defaultValue: "无法加载",
                        comment: "Browse error"
                    ),
                    message: message
                ) {
                    Task { await viewModel.reload() }
                }
            case .loaded:
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    ActivityInboxListRow.listRow(
                        item: item,
                        at: index,
                        isItemLocked: isItemLocked,
                        onLockedItemTap: onLockedItemTap,
                        onOpen: {
                            onSelectActivity(item.id)
                        },
                        onOpenHost: item.hostID.map { hostID in
                            {
                                let name = item.hostDisplayName.trimmingCharacters(in: .whitespacesAndNewlines)
                                onOpenHostProfile?(hostID, name.isEmpty ? hostID : name)
                            }
                        },
                        onJoin: {
                            presentJoinSheet(for: item)
                        }
                    )
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemID: item.id) }
                    }
                }
            }
        }
        .sparkFlatTabListStyle()
        .refreshable {
            await viewModel.reload()
        }
        .sheet(item: $joinSheetItem) { item in
            ActivityBrowseJoinSheet(
                viewModel: coordinator.makeBrowseJoinViewModel(item: item),
                isAuthenticated: isAuthenticated,
                onSignInRequired: {
                    onSignInRequiredForBrowseJoin?(item.id)
                },
                onViewDetail: {
                    onSelectActivity(item.id)
                },
                onJoined: { detail in
                    viewModel.applyJoinedDetail(detail)
                    await onRSVPCompleted?(detail)
                }
            )
        }
        .onChange(of: pendingBrowseJoinActivityID) { _, activityID in
            resumePendingBrowseJoin(activityID: activityID)
        }
        .onChange(of: viewModel.loadState) { _, _ in
            resumePendingBrowseJoin(activityID: pendingBrowseJoinActivityID)
        }
    }

    private var browseEmptyState: some View {
        ContentUnavailableView(
            String(
                localized: "activity.browse.empty.title",
                defaultValue: "暂无公开活动",
                comment: "Browse empty"
            ),
            systemImage: "map",
            description: Text(
                String(
                    localized: "activity.browse.empty.subtitle",
                    defaultValue: "稍后再来看看，或创建自己的活动。",
                    comment: "Browse empty hint"
                )
            )
        )
        .frame(maxWidth: .infinity, minHeight: 320)
        .sparkContentUnavailableCanvas()
    }

    private func presentJoinSheet(for item: ActivityItem) {
        joinSheetItem = item
    }

    private func resumePendingBrowseJoin(activityID: String?) {
        guard let activityID else { return }
        guard viewModel.loadState == .loaded || viewModel.loadState == .empty else { return }
        guard let item = viewModel.items.first(where: { $0.id == activityID }) else { return }
        pendingBrowseJoinActivityID = nil
        presentJoinSheet(for: item)
    }
}

// MARK: - Previews

#Preview("Browse content") {
    let coordinator = ActivityCoordinator(
        feedRepository: MockActivityFeedRepository(),
        browseRepository: MockActivityBrowseRepository()
    )
    let browseViewModel = coordinator.makeBrowseViewModel()
    ActivityBrowseContent(
        viewModel: browseViewModel,
        coordinator: coordinator,
        isItemLocked: { _ in false },
        onLockedItemTap: nil,
        isAuthenticated: true,
        pendingBrowseJoinActivityID: .constant(nil),
        joinSheetItem: .constant(nil),
        onSelectActivity: { _ in },
        onOpenHostProfile: nil,
        onSignInRequiredForBrowseJoin: nil,
        onRSVPCompleted: nil
    )
    .task { await browseViewModel.loadIfNeeded() }
}
