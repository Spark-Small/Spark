// Module: SparkDesignSystem — Toolbar principal segmented control (Phone Recents style).

import SwiftUI

/// System `Picker(.segmented)` for tab-root `ToolbarItem(placement: .principal)`.
public struct SparkToolbarSegmentedPicker<Option: Hashable & Identifiable>: View {
    let options: [Option]
    @Binding var selection: Option
    let title: (Option) -> String
    let accessibilityLabel: String

    public init(
        options: [Option],
        selection: Binding<Option>,
        title: @escaping (Option) -> String,
        accessibilityLabel: String
    ) {
        self.options = options
        _selection = selection
        self.title = title
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(options) { option in
                Text(title(option)).tag(option)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: SparkLayoutMetrics.segmentedControlMaxWidth)
        .accessibilityLabel(accessibilityLabel)
    }
}

extension View {
    /// Fixed secondary segmented row below the navigation bar (e.g. Activity mine · 活动 / 地图).
    public func sparkSegmentToolbarInset<Inset: View>(
        isPresented: Bool = true,
        @ViewBuilder inset: () -> Inset
    ) -> some View {
        modifier(SparkSegmentToolbarInsetModifier(isPresented: isPresented, inset: inset()))
    }
}

private struct SparkSegmentToolbarInsetModifier<Inset: View>: ViewModifier {
    let isPresented: Bool
    let inset: Inset

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            HStack {
                Spacer(minLength: 0)
                inset
                    .opacity(isPresented ? 1 : 0)
                    .allowsHitTesting(isPresented)
                    .accessibilityHidden(!isPresented)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
            .sparkTransparentPinnedInset()
        }
    }
}

#Preview("Toolbar segmented picker") {
    enum PreviewSegment: String, CaseIterable, Identifiable {
        case left, right
        var id: String { rawValue }
    }

    struct Host: View {
        @State private var selection = PreviewSegment.left
        var body: some View {
            List { Text("Row") }
                .navigationTitle("")
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        SparkToolbarSegmentedPicker(
                            options: Array(PreviewSegment.allCases),
                            selection: $selection,
                            title: { $0.rawValue.capitalized },
                            accessibilityLabel: "Preview"
                        )
                    }
                }
        }
    }
    return NavigationStack { Host() }
}
