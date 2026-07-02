// Module: SparkActivity — Map segment and my-activities personal inbox list.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    @ViewBuilder
    var activitiesSegmentContent: some View {
        @Bindable var viewModel = viewModel

        List {
            activitiesListRows()
        }
        .sparkFlatTabListStyle()
        .refreshable {
            guard viewModel.loadState == .loaded else { return }
            await viewModel.load()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private func activitiesListRows() -> some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ActivityAsyncListLoadingRow(
                accessibilityLabel: String(
                    localized: "activity.inbox.loading.a11y",
                    defaultValue: "正在加载活动",
                    comment: "Activity inbox loading"
                )
            )
        case .empty:
            activitiesEmptyState
                .sparkFlatTabListRow()
        case .failure(let message):
            ActivityAsyncListErrorRow(
                title: String(
                    localized: "activity.error.title",
                    defaultValue: "无法加载",
                    comment: "Activity list error"
                ),
                message: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            if viewModel.showsFilterEmptyState, !hasVisibleInboxRequests(for: viewModel.listFilter) {
                activityFilterEmptyContent
                    .sparkFlatTabListRow()
            } else {
                inboxListRows(
                    listItems: ActivityInboxListPresentation.listItems(
                        from: viewModel.filteredItems,
                        filter: viewModel.listFilter,
                        requestActivityIDs: requestActivityIDs(viewModel.listFilter)
                    ),
                    listFilter: viewModel.listFilter
                )
            }
        }
    }

    private func hasVisibleInboxRequests(for filter: ActivityListFilter) -> Bool {
        filter.showsInboxActionItems && !requestActivityIDs(filter).isEmpty
    }

    private var activityFilterEmptyContent: some View {
        @Bindable var viewModel = viewModel
        return ContentUnavailableView {
            Label(
                String(
                    localized: "activity.filter.empty.title",
                    defaultValue: "没有匹配的活动",
                    comment: "Filter empty"
                ),
                systemImage: "line.3.horizontal.decrease.circle"
            )
        } description: {
            Text(
                String(
                    localized: "activity.filter.empty.subtitle",
                    defaultValue: "试试其他筛选，或浏览全部活动。",
                    comment: "Filter empty hint"
                )
            )
        } actions: {
            Button {
                viewModel.listFilter = .all
            } label: {
                Text(
                    String(
                        localized: "activity.filter.showAll",
                        defaultValue: "显示全部",
                        comment: "Reset activity filter"
                    )
                )
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .sparkContentUnavailableCanvas()
    }

    private var activitiesEmptyState: some View {
        ContentUnavailableView {
            Label(
                String(localized: "activity.empty.title", defaultValue: "暂无活动", comment: "Empty activity list"),
                systemImage: "calendar.badge.clock"
            )
        } description: {
            Text(
                String(
                    localized: "activity.empty.subtitle",
                    defaultValue: "去发现有趣的活动，或自己发起一局。",
                    comment: "Empty activity hint"
                )
            )
        } actions: {
            if coordinator.hasBrowseCatalog {
                Button {
                    selectedHomeSegment = .discover
                    showMyActivities = false
                } label: {
                    Text(ActivityHomeSegment.discover.localizedTitle)
                }
                .buttonStyle(.borderedProminent)
            }
            Button {
                pendingCreateActivityDraft = CreateActivityDraft()
            } label: {
                Text(
                    String(localized: "activity.create.a11y", defaultValue: "创建活动", comment: "Create activity")
                )
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .sparkContentUnavailableCanvas()
    }

    var inboxMapContent: some View {
        ActivityInboxMapView(
            activities: viewModel.filteredItems,
            onOpenActivity: { activityID in
                openActivity(activityID)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
