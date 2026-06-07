// Module: SparkTrust — Compact trust score badge.

import SparkDesignSystem
import SwiftUI

public struct TrustBadgeView: View {
    let score: Int
    let hasLiveness: Bool

    public init(score: Int, hasLiveness: Bool) {
        self.score = score
        self.hasLiveness = hasLiveness
    }

    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: hasLiveness ? "checkmark.shield.fill" : "shield")
                .font(.caption.weight(.semibold))
            Text("\(score)")
                .font(.caption.weight(.bold))
        }
        .foregroundStyle(hasLiveness ? Color(.systemGreen) : Color.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .sparkGlassControl(Capsule())
        .accessibilityLabel(accessibilityLabelText)
    }

    private var accessibilityLabelText: String {
        let format = String(
            localized: "trust.badge.a11y.format",
            defaultValue: "信任分 %1$d",
            comment: "Trust badge; %1$d score"
        )
        return String(format: format, locale: .current, score)
    }
}

#Preview {
    TrustBadgeView(score: 65, hasLiveness: true)
}

#Preview("Trust badge — dark") {
    TrustBadgeView(score: 10, hasLiveness: false)
        .environment(\.colorScheme, .dark)
}
