// Module: SparkLikes — Thin daily discover progress above the card stack.

import SwiftUI

struct LikesFeedProgressBar: View {
    let seenCount: Int
    let poolSize: Int

    private var progress: Double {
        guard poolSize > 0 else { return 0 }
        return min(1, Double(seenCount) / Double(poolSize))
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.ultraThinMaterial)
                Capsule()
                    .fill(Color.accentColor.gradient)
                    .frame(width: max(0, proxy.size.width * progress))
            }
        }
        .frame(height: 3)
        .animation(.easeInOut, value: seenCount)
        .accessibilityLabel(
            String(
                localized: "likes.progress.a11y",
                defaultValue: "今日浏览进度",
                comment: "Progress a11y"
            )
        )
        .accessibilityValue("\(seenCount)/\(poolSize)")
    }
}

#Preview {
    LikesFeedProgressBar(seenCount: 12, poolSize: 50)
        .padding()
}
