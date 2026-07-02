// Module: SparkActivity — Pre–iOS 26.1 inline RSVP fallback for activity detail.

import SparkDesignSystem
import SwiftUI

// REASONING: Remove when deployment target ≥ iOS 26.1 (native tab accessory covers invited RSVP).
struct DetailRSVPFallbackModifier: ViewModifier {
    let isVisible: Bool
    let forceInline: Bool
    let kind: ActivityTabBottomAccessoryKind
    let isLoading: Bool
    let onSignIn: () -> Void
    let onSubmitGoing: () -> Void

    func body(content: Content) -> some View {
        if shouldShowInlineFallback {
            content.safeAreaInset(edge: .bottom, spacing: 0) {
                if isVisible, kind.isVisible {
                    ActivityTabBottomFallbackCTA(
                        kind: kind,
                        isLoading: isLoading,
                        action: rsvpAction
                    )
                }
            }
        } else {
            content
        }
    }

    private var shouldShowInlineFallback: Bool {
        if forceInline { return true }
        if #unavailable(iOS 26.1) {
            return true
        }
        return false
    }

    private func rsvpAction() {
        switch kind {
        case .signInToRSVP:
            onSignIn()
        case .rsvpGoing:
            onSubmitGoing()
        case .hidden, .createActivity:
            break
        }
    }
}
