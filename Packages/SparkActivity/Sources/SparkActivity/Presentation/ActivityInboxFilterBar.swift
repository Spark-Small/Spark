// Module: SparkActivity — Inbox filter chips (first row of activity List).

import SparkDesignSystem
import SwiftUI

/// Horizontal activity segments; pin as the first row inside inbox `List` (Messages search-bar pattern).
struct ActivityInboxFilterBar: View {
    @Binding var selection: ActivityListFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ActivityListFilter.allCases) { filter in
                    filterChip(filter)
                }
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        }
        .accessibilityLabel(
            String(
                localized: "activity.filter.a11y",
                defaultValue: "活动筛选",
                comment: "Activity filter picker"
            )
        )
        .sparkFlatTabRowBackground()
    }

    private func filterChip(_ filter: ActivityListFilter) -> some View {
        let isSelected = selection == filter
        return Button {
            selection = filter
        } label: {
            Text(filter.localizedTitle)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .sparkGlassControl(Capsule())
        }
        .buttonStyle(.sparkPressable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview("Activity filter bar") {
    @Previewable @State var filter: ActivityListFilter = .all
    List {
        ActivityInboxFilterBar(selection: $filter)
            .sparkInboxSearchListRow()
        Text("Activity row")
            .sparkFlatTabListRow()
    }
    .sparkFlatTabListStyle()
}
