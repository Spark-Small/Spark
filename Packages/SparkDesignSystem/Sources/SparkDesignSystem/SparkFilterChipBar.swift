// Module: SparkDesignSystem — Horizontal filter chip controls (TAB_SCREENS L3).

import SwiftUI

/// Single-select glass capsule chip — `.subheadline` · pad H14 V10 · selected accent stroke.
public struct SparkFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(title: String, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
                .padding(.horizontal, SparkLayoutMetrics.filterChipHorizontalPadding)
                .padding(.vertical, SparkLayoutMetrics.filterChipVerticalPadding)
                .sparkGlassControl(Capsule())
                .overlay {
                    if isSelected {
                        Capsule()
                            .strokeBorder(
                                Color.accentColor,
                                lineWidth: SparkLayoutMetrics.filterChipStrokeWidth
                            )
                    }
                }
        }
        .buttonStyle(.sparkPressable)
        .sparkMinimumTouchTarget()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Horizontally scrolling filter chip row — mounted in `SparkTabTopAccessory` under the navigation bar.
public struct SparkHorizontalFilterChipBar<Option: Hashable & Identifiable>: View {
    let options: [Option]
    let selection: Option
    let title: (Option) -> String
    let onSelect: (Option) -> Void
    let accessibilityLabel: String

    public init(
        options: [Option],
        selection: Option,
        title: @escaping (Option) -> String,
        onSelect: @escaping (Option) -> Void,
        accessibilityLabel: String
    ) {
        self.options = options
        self.selection = selection
        self.title = title
        self.onSelect = onSelect
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SparkLayoutMetrics.filterChipSpacing) {
                ForEach(options) { option in
                    SparkFilterChip(
                        title: title(option),
                        isSelected: selection == option
                    ) {
                        onSelect(option)
                    }
                    .accessibilityHint(
                        String(
                            localized: "spark.filter.chip.hint",
                            defaultValue: "筛选列表内容",
                            comment: "Filter chip hint"
                        )
                    )
                }
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        }
        .scrollClipDisabled()
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
        .sparkTransparentPinnedInset()
        .sensoryFeedback(.selection, trigger: selection)
    }
}

#Preview("Filter chips") {
    enum PreviewFilter: String, CaseIterable, Identifiable {
        case all, today, week, social
        var id: String { rawValue }
    }

    struct PreviewHost: View {
        @State private var selection = PreviewFilter.all

        var body: some View {
            SparkHorizontalFilterChipBar(
                options: Array(PreviewFilter.allCases),
                selection: selection,
                title: \.rawValue,
                onSelect: { selection = $0 },
                accessibilityLabel: "Filters"
            )
        }
    }
    return PreviewHost()
}

#Preview("Filter chips — dark") {
    SparkPreviewSupport.darkMode {
        SparkFilterChip(title: "本周", isSelected: true, action: {})
    }
}

#Preview("Filter chips — accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        SparkFilterChip(title: "全部", isSelected: false, action: {})
    }
}
