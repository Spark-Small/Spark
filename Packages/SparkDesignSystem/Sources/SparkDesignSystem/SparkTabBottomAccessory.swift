// Module: SparkDesignSystem — Tab bar bottom primary action (iOS 26+ tabViewBottomAccessory).

import SwiftUI

/// Full-width label-only CTA docked above the system tab bar.
@available(iOS 26.1, *)
public struct SparkTabBottomAccessory: View {
    private let title: String
    private let systemImage: String
    private let accessibilityHint: String
    private let isInteractionEnabled: Bool
    private let isLoading: Bool
    private let action: () -> Void

    public init(
        title: String,
        systemImage: String,
        accessibilityHint: String,
        isInteractionEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.accessibilityHint = accessibilityHint
        self.isInteractionEnabled = isInteractionEnabled
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .controlSize(.regular)
                } else {
                    Label(title, systemImage: systemImage)
                        .font(.body.weight(.semibold))
                        .labelStyle(.titleAndIcon)
                }
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: SparkAuthLayout.signInButtonMinHeight)
        }
        .buttonStyle(.borderless)
        .disabled(!isInteractionEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isLoading ? [.isButton, .updatesFrequently] : .isButton)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkLayoutMetrics.compactVerticalPadding)
    }
}
