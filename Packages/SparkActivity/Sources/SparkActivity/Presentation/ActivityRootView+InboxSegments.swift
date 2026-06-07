// Module: SparkActivity — Segmented inbox: 活动 / 地图.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var activityInboxSegmentToolbarPicker: some View {
        Picker("", selection: $selectedInboxSegment) {
            ForEach(ActivityInboxSegment.allCases) { segment in
                Text(segment.localizedTitle).tag(segment)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: SparkLayoutMetrics.segmentedControlMaxWidth)
        .accessibilityLabel(
            String(
                localized: "activity.inbox.segment.a11y",
                defaultValue: "活动视图",
                comment: "Activity inbox segment picker"
            )
        )
    }

    @ViewBuilder
    var loadedInboxSegmentContent: some View {
        inboxSegmentInstantContent
    }

    @ViewBuilder
    private var inboxSegmentInstantContent: some View {
        switch selectedInboxSegment {
        case .activities:
            activitiesSegmentContent
        case .map:
            inboxMapContent
        }
    }

    @ViewBuilder
    var activitiesSegmentContent: some View {
        Group {
            switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkLoadingAccessibilityLabel(
                    String(
                        localized: "activity.inbox.loading.a11y",
                        defaultValue: "正在加载活动",
                        comment: "Activity inbox loading"
                    )
                )
        case .empty:
            activitiesEmptyState
        case .failure:
            EmptyView()
        case .loaded:
            loadedActivitiesListContent
        }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    @ViewBuilder
    private var loadedActivitiesListContent: some View {
        @Bindable var viewModel = viewModel
        Group {
            if viewModel.showsFilterEmptyState, !hasVisibleInboxRequests(for: viewModel.listFilter) {
                activityFilterEmptyContent
            } else if usesSplitLayout {
                activityInboxList(selection: $selectedActivityID)
            } else {
                activityInboxList(selection: nil)
            }
        }
        .refreshable {
            await viewModel.load()
        }
    }

    private func hasVisibleInboxRequests(for filter: ActivityListFilter) -> Bool {
        filter.showsInboxActionItems && !requestActivityIDs(filter).isEmpty
    }

    private var activityFilterEmptyContent: some View {
        @Bindable var viewModel = viewModel
        return ScrollView {
            ContentUnavailableView {
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
            .padding(.top, SparkLayoutMetrics.sectionVerticalPadding)
        }
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
                    showBrowse = true
                } label: {
                    Text(
                        String(
                            localized: "activity.browse.entry",
                            defaultValue: "逛局",
                            comment: "Browse public activities"
                        )
                    )
                }
                .buttonStyle(.borderedProminent)
            }
            Button {
                showCreateActivity = true
            } label: {
                Text(
                    String(localized: "activity.create.a11y", defaultValue: "创建活动", comment: "Create activity")
                )
            }
            .buttonStyle(.bordered)
        }
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
