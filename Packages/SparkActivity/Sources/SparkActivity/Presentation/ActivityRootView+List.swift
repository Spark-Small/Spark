// Module: SparkActivity — List shell, split layout, and feed content.

import SparkDesignSystem
import SwiftUI

extension ActivityRootView {
    var compactRoot: some View {
        NavigationStack(path: $navigationPath) {
            activityListShell
                .navigationDestination(for: ActivityItem.self) { item in
                    activityDetailView(activityID: item.id)
                }
                .navigationDestination(for: String.self) { activityID in
                    externalActivityDetailView(activityID: activityID)
                }
        }
    }

    var splitRoot: some View {
        NavigationSplitView {
            activityListShell
        } detail: {
            if let activityID = selectedActivityID {
                activityDetailView(activityID: activityID)
            } else {
                ContentUnavailableView {
                    Label(
                        String(
                            localized: "activity.split.empty.title",
                            defaultValue: "选择活动",
                            comment: "Split activity placeholder"
                        ),
                        systemImage: "calendar"
                    )
                } description: {
                    Text(
                        String(
                            localized: "activity.split.empty.subtitle",
                            defaultValue: "从左侧列表查看活动详情",
                            comment: "Split activity hint"
                        )
                    )
                }
            }
        }
    }

    var activityListShell: some View {
        SparkScreenContainer(
            navigationTitle: String(localized: "screen.activity", defaultValue: "活动", comment: "Activity screen"),
            embedding: .none
        ) {
            listContent
                .task {
                    if viewModel.loadState == .idle {
                        await viewModel.load()
                    }
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if coordinator.hasBrowseCatalog {
                        Button {
                            showBrowse = true
                        } label: {
                            Label(
                                String(
                                    localized: "activity.browse.entry",
                                    defaultValue: "逛局",
                                    comment: "Browse public activities"
                                ),
                                systemImage: "map"
                            )
                        }
                    }
                    Button {
                        showNotificationSettings = true
                    } label: {
                        Label(
                            String(
                                localized: "activity.settings.menu",
                                defaultValue: "活动提醒",
                                comment: "Activity settings"
                            ),
                            systemImage: "bell"
                        )
                    }
                    Button {
                        showCreateActivity = true
                    } label: {
                        Label(
                            String(localized: "activity.create.a11y", defaultValue: "创建活动", comment: "Create activity"),
                            systemImage: "plus"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    var notificationSettingsSheet: some View {
        NavigationStack {
            Form {
                ActivityNotificationSettingsSection()
            }
            .navigationTitle(
                String(localized: "activity.settings.title", defaultValue: "活动设置", comment: "Settings title")
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "action.done", defaultValue: "完成", comment: "Done")) {
                        showNotificationSettings = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    var listContent: some View {
        @Bindable var viewModel = viewModel
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
            ContentUnavailableView(
                String(localized: "activity.empty.title", defaultValue: "暂无活动", comment: "Empty activity list"),
                systemImage: "calendar.badge.clock",
                description: Text(
                    String(localized: "activity.empty.subtitle", defaultValue: "稍后再来看看", comment: "Empty activity hint")
                )
            )
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "activity.error.title", defaultValue: "无法加载", comment: "Activity list error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .loaded:
            VStack(spacing: 0) {
                Picker("", selection: $viewModel.listFilter) {
                    ForEach(ActivityListFilter.allCases) { filter in
                        Text(filter.localizedTitle).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if viewModel.showsFilterEmptyState {
                    ContentUnavailableView(
                        String(
                            localized: "activity.filter.empty.title",
                            defaultValue: "没有匹配的活动",
                            comment: "Filter empty"
                        ),
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text(
                            String(
                                localized: "activity.filter.empty.subtitle",
                                defaultValue: "试试其他筛选，或浏览全部活动。",
                                comment: "Filter empty hint"
                            )
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if usesSplitLayout {
                    List(viewModel.filteredItems, id: \.id, selection: $selectedActivityID) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        activityRow(for: item, at: index)
                            .tag(item.id)
                    }
                    .sparkScreenListStyle()
                    .refreshable {
                        await viewModel.load()
                    }
                } else {
                    List(viewModel.filteredItems, id: \.id) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        activityRow(for: item, at: index)
                    }
                    .sparkScreenListStyle()
                    .refreshable {
                        await viewModel.load()
                    }
                }
            }
        }
    }
}
