// Module: SparkAuth — Shared Form chrome for auth screens (TAB_SCREENS L3 / SparkDesignSystem).

import SparkDesignSystem
import SwiftUI

extension View {
    /// Grouped Form canvas: `systemGroupedBackground`, hidden scroll background, keyboard dismiss.
    func sparkAuthFormChrome() -> some View {
        scrollContentBackground(.hidden)
            .sparkScreenCanvasBackground()
            .sparkDismissesKeyboardOnScroll()
    }

    /// Readable width on iPad / regular size class only; compact width stays edge-to-edge.
    func sparkAuthReadableFormWidth() -> some View {
        modifier(SparkAuthReadableFormWidthModifier())
    }

    /// Full-screen grouped canvas for root `LoginView` (behind `NavigationStack` + `Form`).
    func sparkAuthLoginScreenBackground() -> some View {
        background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    /// Full-width primary CTA row inside a Form section.
    func sparkAuthFormPrimaryRow() -> some View {
        listRowInsets(
            EdgeInsets(
                top: SparkLayoutMetrics.compactVerticalPadding,
                leading: SparkLayoutMetrics.standardHorizontalPadding,
                bottom: SparkLayoutMetrics.compactVerticalPadding,
                trailing: SparkLayoutMetrics.standardHorizontalPadding
            )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    /// Credential `TextField` rows — consistent edge-to-edge separators in grouped Form sections.
    func sparkAuthFormCredentialRow() -> some View {
        alignmentGuide(.listRowSeparatorLeading) { _ in 0 }
            .alignmentGuide(.listRowSeparatorTrailing) { dimensions in
                dimensions.width
            }
    }
}

enum SparkAuthLayoutMetrics {
    /// Fixed trailing slot beside the phone field (arrow · spinner · countdown).
    static let phoneTrailingSlotWidth: CGFloat = 56
    /// Standard navigation-bar control diameter (HIG 44pt).
    static let thirdPartySignInButtonSize: CGFloat = SparkLayoutMetrics.minimumTouchTarget
    /// Horizontal gap between third-party sign-in circles (TAB_SCREENS L3 · H20).
    static let thirdPartySignInSpacing: CGFloat = SparkLayoutMetrics.discoverActionBarSpacing
    /// Vertical inset for the third-party bar above the home indicator.
    static let thirdPartySignInVerticalPadding: CGFloat = SparkLayoutMetrics.discoverActionBarVerticalPadding
}

private struct SparkAuthReadableFormWidthModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content.sparkReadableWidth(SparkLayoutMetrics.matchCardMaxWidth)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}
