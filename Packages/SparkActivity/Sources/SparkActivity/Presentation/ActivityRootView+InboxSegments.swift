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
        case .discover:
            discoverSegmentContent
        case .mine:
            mineSegmentContent
        }
    }

    @ViewBuilder
    var discoverSegmentContent: some View {
        if coordinator.hasBrowseCatalog {
            ActivityBrowseSegmentContent(
                viewModel: browseViewModel,
                onSelectActivity: { activityID in
                    openActivity(activityID, context: .discover)
                }
            )
        } else {
            ContentUnavailableView(
                String(
                    localized: "activity.discover.unavailable.title",
                    defaultValue: "发现暂不可用",
                    comment: "Browse catalog missing"
                ),
                systemImage: "calendar.badge.exclamationmark",
                description: Text(
                    String(
                        localized: "activity.discover.unavailable.subtitle",
                        defaultValue: "请稍后再试，或查看「我的行程」。",
                        comment: "Browse unavailable hint"
                    )
                )
            )
            .sparkContentUnavailableCanvas()
        }
    }

    @ViewBuilder
    var mineSegmentContent: some View {
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
            if viewModel.showsFilterEmptyState {
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
                String(localized: "activity.empty.title", defaultValue: "暂无行程", comment: "Empty itinerary list"),
                systemImage: "figure.walk"
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
                    selectedInboxSegment = .discover
                } label: {
                    Text(
                        String(
                            localized: "activity.discover.entry",
                            defaultValue: "去发现",
                            comment: "Switch to discover segment"
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

    var mineMapOverlay: some View {
        ActivityInboxMapView(
            activities: viewModel.filteredItems,
            presentation: .itinerary,
            onOpenActivity: { activityID in
                openActivity(activityID, context: .inbox)
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
