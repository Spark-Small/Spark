// Module: SparkActivity — Inline browse list for Activity Tab discover segment (W7).

import SparkDesignSystem
import SwiftUI

struct ActivityBrowseSegmentContent: View {
    @Bindable var viewModel: ActivityBrowseViewModel
    let onSelectActivity: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                categoryPicker
                timeWindowPicker
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.activityFilterVerticalPadding)

            browseBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var browseBody: some View {
        switch viewModel.loadState {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .sparkLoadingAccessibilityLabel(
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
            .sparkContentUnavailableCanvas()
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
                ActivityInboxListRow(item: item, isLocked: false, showsBrowseTrustSignals: true)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectActivity(item.id)
                    }
                    .sparkFlatTabListRow()
                    .accessibilityAddTraits(.isButton)
                    .onAppear {
                        Task { await viewModel.loadMoreIfNeeded(currentItemID: item.id) }
                    }
            }
            .sparkFlatTabListStyle()
            .refreshable {
                await viewModel.reload()
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
