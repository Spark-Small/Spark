// Module: SparkActivity — Inbox filter chips (my-activities sheet top accessory).

import SparkDesignSystem
import SwiftUI

struct ActivityInboxFilterBar: View {
    @Binding var selection: ActivityListFilter

    var body: some View {
        SparkHorizontalFilterChipBar(
            options: Array(ActivityListFilter.allCases),
            selection: selection,
            title: \.localizedTitle,
            onSelect: { selection = $0 },
            accessibilityLabel: String(
                localized: "activity.filter.a11y",
                defaultValue: "活动筛选",
                comment: "Activity filter picker"
            )
        )
        .id(selection)
    }
}

#Preview("Activity filter bar") {
    @Previewable @State var filter: ActivityListFilter = .all
    ActivityInboxFilterBar(selection: $filter)
}

#Preview("Activity filter bar — accessibility XL") {
    @Previewable @State var filter: ActivityListFilter = .hosting
    SparkPreviewSupport.accessibilityXL {
        ActivityInboxFilterBar(selection: $filter)
    }
}
