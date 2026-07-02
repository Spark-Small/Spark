// Module: SparkDesignSystem — Shared #Preview helpers (HIG: dark / XL).

import SwiftUI

public enum SparkPreviewSupport {
    public static func darkMode<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().preferredColorScheme(.dark)
    }

    public static func accessibilityXL<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().environment(\.sizeCategory, .accessibilityExtraExtraLarge)
    }
}
