// Module: SparkDesignSystem — Shared #Preview helpers (HIG: dark / XL / iPad).

import SwiftUI

public enum SparkPreviewSupport {
    public static func darkMode<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().preferredColorScheme(.dark)
    }

    public static func accessibilityXL<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().environment(\.sizeCategory, .accessibilityExtraExtraLarge)
    }

    /// Simulates iPad regular width for NavigationSplitView previews.
    public static func iPadRegular<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().environment(\.horizontalSizeClass, .regular)
    }
}
