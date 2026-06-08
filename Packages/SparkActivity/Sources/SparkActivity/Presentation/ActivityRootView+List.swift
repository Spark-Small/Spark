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
                .navigationSplitViewColumnWidth(
                    min: 280,
                    ideal: SparkLayoutMetrics.navigationSplitSidebarIdealWidth,
                    max: 400
                )
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
            navigationTitle: "",
            titleDisplayMode: .inline,
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
            ToolbarItem(placement: .principal) {
                if showsInboxSegmentPicker {
                    activityInboxSegmentToolbarPicker
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if selectedInboxSegment == .mine {
                        Button {
                            showMineMap = true
                        } label: {
                            Label(
                                String(
                                    localized: "activity.segment.map",
                                    defaultValue: "地图",
                                    comment: "Activity inbox map segment"
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
        .sparkPhoneStyleNavigationBar()
        .environment(activityFavoriteStore)
    }

    private var showsInboxSegmentPicker: Bool {
        switch viewModel.loadState {
        case .failure:
            false
        case .idle, .loading, .empty, .loaded:
            true
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
        switch viewModel.loadState {
        case .failure(let message):
            SparkRetryUnavailableView(
                title: String(localized: "activity.error.title", defaultValue: "无法加载", comment: "Activity list error"),
                description: message
            ) {
                Task { await viewModel.load() }
            }
        case .idle, .loading, .empty, .loaded:
            loadedInboxSegmentContent
        }
    }

    @ViewBuilder
    func activityInboxList(selection: Binding<String?>?) -> some View {
        @Bindable var viewModel = viewModel
        let listItems = ActivityInboxListPresentation.listItems(
            from: viewModel.filteredItems,
            filter: viewModel.listFilter,
            requestActivityIDs: requestActivityIDs(viewModel.listFilter)
        )
        Group {
            if let selection {
                List(selection: selection) {
                    ActivityInboxFilterBar(selection: $viewModel.listFilter)
                        .sparkInboxSearchListRow()
                    actionItemsInset(viewModel.listFilter)
                    ForEach(listItems, id: \.id) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        activityRow(for: item, at: index)
                            .tag(item.id)
                    }
                }
            } else {
                List {
                    ActivityInboxFilterBar(selection: $viewModel.listFilter)
                        .sparkInboxSearchListRow()
                    actionItemsInset(viewModel.listFilter)
                    ForEach(listItems, id: \.id) { item in
                        let index = viewModel.items.firstIndex(where: { $0.id == item.id }) ?? 0
                        activityRow(for: item, at: index)
                    }
                }
            }
        }
        .sparkFlatTabListStyle()
    }
}
