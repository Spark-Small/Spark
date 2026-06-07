// Module: SparkDesignSystem — VoiceOver labels for loading indicators.

import SwiftUI

public extension View {
    /// Full-screen or primary loading indicator label for VoiceOver.
    func sparkLoadingAccessibilityLabel(
        _ description: String = String(
            localized: "common.loading.a11y",
            defaultValue: "正在加载",
            comment: "Loading indicator"
        )
    ) -> some View {
        accessibilityLabel(description)
    }

    /// Inline pagination / load-more spinner label for VoiceOver.
    func sparkLoadingMoreAccessibilityLabel(
        _ description: String = String(
            localized: "common.loadingMore.a11y",
            defaultValue: "正在加载更多",
            comment: "Load more indicator"
        )
    ) -> some View {
        accessibilityLabel(description)
    }
}
