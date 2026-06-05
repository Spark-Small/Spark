// Module: SparkLikes — Preview helpers (forwards to SparkDesignSystem).

import SparkDesignSystem
import SwiftUI

enum LikesPreviewSupport {
    static func darkMode<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.darkMode(content)
    }

    static func accessibilityXL<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.accessibilityXL(content)
    }

    static func iPadRegular<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        SparkPreviewSupport.iPadRegular(content)
    }
}
