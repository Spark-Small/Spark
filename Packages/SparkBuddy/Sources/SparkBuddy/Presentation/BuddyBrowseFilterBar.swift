// Module: SparkBuddy — Browse service category chips (Activity parity).

import SparkDesignSystem
import SwiftUI

struct BuddyBrowseFilterBar: View {
    @Bindable var viewModel: BuddyViewModel

    var body: some View {
        SparkHorizontalFilterChipBar(
            options: Array(BuddyServiceFilter.allCases),
            selection: viewModel.selectedServiceFilter,
            title: \.localizedTitle,
            onSelect: { viewModel.selectedServiceFilter = $0 },
            accessibilityLabel: String(
                localized: "buddy.browse.filter.a11y",
                defaultValue: "陪玩分类筛选",
                comment: "Buddy browse category filter picker"
            )
        )
        .id(viewModel.selectedServiceFilter)
    }
}

#Preview("Buddy browse filters") {
    BuddyBrowseFilterBar(viewModel: BuddyViewModel(repository: MockBuddyRepository()))
}

#Preview("Buddy browse filters — dark") {
    SparkPreviewSupport.darkMode {
        BuddyBrowseFilterBar(viewModel: BuddyViewModel(repository: MockBuddyRepository()))
    }
}
