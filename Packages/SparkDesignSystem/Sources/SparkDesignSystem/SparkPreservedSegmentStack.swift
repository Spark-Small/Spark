// Module: SparkDesignSystem — Preserve segmented tab content to avoid switch flicker.

import SwiftUI

/// Keeps every segment's scroll surface mounted; toggles visibility instead of `switch` teardown.
public struct SparkPreservedSegmentStack<Segment: Hashable, Content: View>: View {
    let selection: Segment
    let segments: [Segment]
    @ViewBuilder let content: (Segment) -> Content

    public init(
        selection: Segment,
        segments: [Segment],
        @ViewBuilder content: @escaping (Segment) -> Content
    ) {
        self.selection = selection
        self.segments = segments
        self.content = content
    }

    public var body: some View {
        ZStack(alignment: .top) {
            ForEach(segments, id: \.self) { segment in
                content(segment)
                    .opacity(selection == segment ? 1 : 0)
                    .allowsHitTesting(selection == segment)
                    .accessibilityHidden(selection != segment)
                    .zIndex(selection == segment ? 1 : 0)
            }
        }
        .animation(nil, value: selection)
    }
}

#Preview("Preserved segments") {
    enum PreviewSegment: String, CaseIterable, Hashable {
        case left, right
    }

    struct Host: View {
        @State private var selection = PreviewSegment.left

        var body: some View {
            VStack {
                Picker("", selection: $selection) {
                    Text("Left").tag(PreviewSegment.left)
                    Text("Right").tag(PreviewSegment.right)
                }
                .pickerStyle(.segmented)
                .padding()

                SparkPreservedSegmentStack(selection: selection, segments: Array(PreviewSegment.allCases)) { segment in
                    List {
                        Text(segment == .left ? "DM row" : "Group row")
                    }
                    .sparkFlatTabListStyle()
                }
            }
        }
    }
    return Host()
}
