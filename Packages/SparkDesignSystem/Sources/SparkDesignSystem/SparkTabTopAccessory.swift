// Module: SparkDesignSystem — Navigation-area top accessory (mirror of tabViewBottomAccessory placement).

import SwiftUI

/// Filter / control row docked below the navigation bar while scroll content passes underneath.
public struct SparkTabTopAccessory<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .sparkTransparentPinnedInset()
    }
}

private struct SparkTabTopAccessoryModifier<Accessory: View>: ViewModifier {
    let isEnabled: Bool
    let accessory: Accessory

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .top, spacing: 0) {
            if isEnabled {
                SparkTabTopAccessory {
                    accessory
                }
            }
        }
    }
}

extension View {
    /// Pins an accessory under the navigation bar; list scrolls beneath while the bar can collapse on scroll.
    public func sparkTabTopAccessory<Accessory: View>(
        isEnabled: Bool,
        @ViewBuilder accessory: () -> Accessory
    ) -> some View {
        modifier(SparkTabTopAccessoryModifier(isEnabled: isEnabled, accessory: accessory()))
    }
}
