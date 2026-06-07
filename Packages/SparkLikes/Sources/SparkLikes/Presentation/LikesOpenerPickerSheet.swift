// Module: SparkLikes — Optional compliment bubble picker on right-swipe.

import SparkDesignSystem
import SwiftUI

struct LikesOpenerPickerSheet: View {
    let suggestions: [String]
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { _, line in
                        Button {
                            onSelect(line)
                            dismiss()
                        } label: {
                            Text(line)
                                .font(.body)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .sparkGlassSurface(RoundedRectangle.sparkCard)
                        }
                        .buttonStyle(.sparkPressable)
                    }
                }
                .padding()
            }
            .accessibilityElement(children: .contain)
            .navigationTitle(
                String(
                    localized: "likes.opener.title",
                    defaultValue: "附一句开场白",
                    comment: "Opener picker title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(
                        String(localized: "action.later", defaultValue: "稍后再说", comment: "Skip opener")
                    ) {
                        onSelect(nil)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    LikesOpenerPickerSheet(suggestions: ["你好", "想认识你"], onSelect: { _ in })
}
