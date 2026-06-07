// Module: SparkActivity — Public activity browse (ADR-0003).

import SparkDesignSystem
import SwiftUI

public struct ActivityBrowseListView: View {
    @State private var viewModel: ActivityBrowseViewModel
    @Environment(\.dismiss) private var dismiss

    private let coordinator: ActivityCoordinator
    private let onRSVPCompleted: ((ActivityDetail) async -> Void)?
    private let onOpenGroupChat: ((ActivityDetail) async -> Void)?

    public init(
        coordinator: ActivityCoordinator,
        onRSVPCompleted: ((ActivityDetail) async -> Void)? = nil,
        onOpenGroupChat: ((ActivityDetail) async -> Void)? = nil
    ) {
        _viewModel = State(initialValue: coordinator.makeBrowseViewModel())
        self.coordinator = coordinator
        self.onRSVPCompleted = onRSVPCompleted
        self.onOpenGroupChat = onOpenGroupChat
    }

    public var body: some View {
        NavigationStack {
            SparkScreenContainer(
                navigationTitle: String(
                    localized: "activity.browse.title",
                    defaultValue: "逛局",
                    comment: "Browse activities title"
                ),
                embedding: .none
            ) {
                content
                    .task { await viewModel.loadIfNeeded() }
            }
            .navigationDestination(for: ActivityItem.self) { item in
                ActivityDetailView(
                    activityID: item.id,
                    coordinator: coordinator,
                    context: .discover,
                    onRSVPCompleted: onRSVPCompleted,
                    onOpenGroupChat: onOpenGroupChat
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "action.close", defaultValue: "关闭", comment: "Close")) {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                categoryPicker
                timeWindowPicker
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            switch viewModel.loadState {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(
                        String(
                            localized: "activity.browse.loading.a11y",
                            defaultValue: "正在加载活动",
                            comment: "Browse loading"
                        )
                    )
            case .empty:
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
            case .failure(let message):
                SparkRetryUnavailableView(
                    title: String(
                        localized: "activity.browse.error.title",
                        defaultValue: "无法加载",
                        comment: "Browse error"
                    ),
                    description: message
                ) {
                    Task { await viewModel.reload() }
                }
            case .loaded:
                List(viewModel.items) { item in
                    NavigationLink(value: item) {
                        ActivityInboxListRow(item: item, isLocked: false)
                    }
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemID: item.id) }
                    }
                }
                .sparkScreenListStyle()
                .refreshable {
                    await viewModel.reload()
                }
            }
        }
    }

    private var categoryPicker: some View {
        Picker(
            String(localized: "activity.browse.category", defaultValue: "分类", comment: "Category filter"),
            selection: Binding(
                get: { viewModel.selectedCategory },
                set: { viewModel.selectedCategory = $0 }
            )
        ) {
            Text(String(localized: "activity.browse.category.all", defaultValue: "全部", comment: "All categories"))
                .tag(String?.none)
            ForEach(Array(ActivityBrowseViewModel.categoryOptions.compactMap { $0 }.enumerated()), id: \.offset) { _, category in
                Text(category).tag(Optional(category))
            }
        }
        .pickerStyle(.segmented)
    }

    private var timeWindowPicker: some View {
        Picker(
            String(localized: "activity.browse.time", defaultValue: "时间", comment: "Time filter"),
            selection: Binding(
                get: { viewModel.selectedTimeWindow },
                set: { viewModel.selectedTimeWindow = $0 }
            )
        ) {
            ForEach(ActivityBrowseTimeWindow.allCases, id: \.rawValue) { window in
                Text(window.localizedTitle).tag(window)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    ActivityBrowseListView(
        coordinator: ActivityCoordinator(
            feedRepository: MockActivityFeedRepository(),
            browseRepository: MockActivityBrowseRepository()
        )
    )
}
