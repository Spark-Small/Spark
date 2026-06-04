// Module: SparkLikes — Preview helpers (dark mode + Dynamic Type).

import SwiftUI

enum LikesPreviewSupport {
    static func darkMode<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().preferredColorScheme(.dark)
    }

    static func accessibilityXL<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content().environment(\.sizeCategory, .accessibilityExtraExtraLarge)
    }
}
