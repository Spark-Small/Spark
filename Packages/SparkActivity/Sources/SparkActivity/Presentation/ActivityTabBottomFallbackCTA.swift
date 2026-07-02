// Module: SparkActivity — Reusable bottom CTA chrome (legacy tab accessory fallback).

import SparkDesignSystem
import SwiftUI

/// Full-width primary action when `tabViewBottomAccessory` is unavailable.
struct ActivityTabBottomFallbackCTA: View {
    let kind: ActivityTabBottomAccessoryKind
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.regular)
                } else {
                    Label(kind.title, systemImage: kind.systemImage)
                        .font(.body.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: SparkAuthLayout.signInButtonMinHeight)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!kind.isInteractionEnabled || isLoading)
        .accessibilityLabel(kind.title)
        .accessibilityHint(kind.accessibilityHint)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
        .background(.regularMaterial)
    }
}

#Preview("RSVP fallback") {
    ActivityTabBottomFallbackCTA(
        kind: .rsvpGoing(isEnabled: true),
        isLoading: false,
        action: {}
    )
    .padding()
}
