// Module: SparkDesignSystem — Plain button with spring press feedback (HIG).

import SwiftUI

/// Drop-in replacement for `.buttonStyle(.plain)` with scale + opacity press feedback.
public struct SparkPressableButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(
                reduceMotion ? nil : .spring(response: 0.25, dampingFraction: 0.72),
                value: configuration.isPressed
            )
    }
}

public extension ButtonStyle where Self == SparkPressableButtonStyle {
    static var sparkPressable: SparkPressableButtonStyle { SparkPressableButtonStyle() }
}

public extension View {
    /// Dismiss keyboard interactively on scroll (forms and chat composers).
    func sparkDismissesKeyboardOnScroll() -> some View {
        scrollDismissesKeyboard(.interactively)
    }
}

public extension RoundedRectangle {
    /// Standard continuous card shape (≥16pt corner, HIG-aligned).
    static var sparkCard: RoundedRectangle {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
    }
}
