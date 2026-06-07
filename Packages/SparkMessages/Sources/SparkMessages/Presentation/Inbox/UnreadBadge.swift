// Module: SparkMessages — Numeric unread indicator for inbox rows.

import SparkDesignSystem
import SwiftUI

struct UnreadBadge: View {
    let count: Int

    var body: some View {
        if let label = badgeLabel {
            Text(label)
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(
                    width: usesCircularFrame ? SparkLayoutMetrics.inboxUnreadBadgeMinSize : nil,
                    height: SparkLayoutMetrics.inboxUnreadBadgeMinSize
                )
                .padding(.horizontal, usesCircularFrame ? 0 : SparkLayoutMetrics.inboxUnreadBadgeWideHorizontalPadding)
                .background(Color.accentColor, in: Capsule())
                .accessibilityLabel(accessibilityLabel)
        }
    }

    private var usesCircularFrame: Bool {
        count <= 9
    }

    private var badgeLabel: String? {
        guard count >= 1 else { return nil }
        return count > 99 ? "99+" : "\(count)"
    }

    private var accessibilityLabel: String {
        let format = String(
            localized: "messages.unread.count.format",
            defaultValue: "%lld 条未读",
            comment: "Unread count badge"
        )
        return String(format: format, locale: .current, count)
    }
}

#Preview("Unread badge") {
    HStack(spacing: 16) {
        UnreadBadge(count: 1)
        UnreadBadge(count: 12)
        UnreadBadge(count: 120)
    }
    .padding()
}
