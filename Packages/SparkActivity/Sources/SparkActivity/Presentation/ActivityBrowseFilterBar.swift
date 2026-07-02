// Module: SparkActivity — Discover filter chips (top accessory).

import SparkDesignSystem
import SwiftUI

struct ActivityBrowseFilterBar: View {
    @Bindable var viewModel: ActivityBrowseViewModel

    var body: some View {
        SparkHorizontalFilterChipBar(
            options: Array(ActivityBrowseFilter.allCases),
            selection: viewModel.selectedFilter,
            title: \.localizedTitle,
            onSelect: { viewModel.selectedFilter = $0 },
            accessibilityLabel: String(
                localized: "activity.browse.filter.a11y",
                defaultValue: "活动分类筛选",
                comment: "Activity browse filter picker"
            )
        )
        .id(viewModel.selectedFilter)
    }
}

#Preview("Discover filters") {
    ActivityBrowseFilterBar(
        viewModel: ActivityBrowseViewModel(repository: MockActivityBrowseRepository())
    )
}

#Preview("Discover filters — dark") {
    SparkPreviewSupport.darkMode {
        ActivityBrowseFilterBar(
            viewModel: ActivityBrowseViewModel(repository: MockActivityBrowseRepository())
        )
    }
}
