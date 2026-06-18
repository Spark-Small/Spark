// Module: SparkActivity — Inline browse list + map for Activity Tab discover segment.

import SparkCore
import SparkDesignSystem
import SwiftUI

struct ActivityBrowseSegmentContent: View {
    @Bindable var viewModel: ActivityBrowseViewModel
    @State private var viewMode: ActivityDiscoverViewMode = .list
    let onSelectActivity: (String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                discoverViewModePicker
                sceneCategoryChips
                timeWindowPicker
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.activityFilterVerticalPadding)

            browseBody
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .task { await viewModel.loadIfNeeded() }
        .onChange(of: viewMode) { _, mode in
            IntegrationTelemetry.discoverViewMode(mode.rawValue)
            // REASONING: Map users usually care about near-term events; default to this week.
            if mode == .map, viewModel.selectedTimeWindow == .all {
                viewModel.selectedTimeWindow = .thisWeek
            }
        }
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
                        defaultValue: "换个分类或时间试试，或创建自己的活动。",
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
            if viewMode == .map {
                ActivityInboxMapView(
                    activities: viewModel.items,
                    presentation: .discover,
                    onOpenActivity: onSelectActivity
                )
            } else {
                browseList
            }
        }
    }

    private var browseList: some View {
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

    private var discoverViewModePicker: some View {
        Picker("", selection: $viewMode) {
            ForEach(ActivityDiscoverViewMode.allCases) { mode in
                Text(mode.localizedTitle).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel(
            String(
                localized: "activity.discover.mode.a11y",
                defaultValue: "发现视图",
                comment: "Discover view mode picker"
            )
        )
    }

    private var sceneCategoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                sceneChip(
                    title: String(
                        localized: "activity.browse.category.all",
                        defaultValue: "全部",
                        comment: "All categories"
                    ),
                    isSelected: viewModel.selectedCategory == nil
                ) {
                    viewModel.selectedCategory = nil
                }
                ForEach(Array(ActivityBrowseViewModel.categoryOptions.compactMap { $0 }.enumerated()), id: \.offset) { _, category in
                    sceneChip(title: category, isSelected: viewModel.selectedCategory == category) {
                        viewModel.selectedCategory = category
                    }
                }
            }
        }
    }

    private func sceneChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .sparkGlassControl(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
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
