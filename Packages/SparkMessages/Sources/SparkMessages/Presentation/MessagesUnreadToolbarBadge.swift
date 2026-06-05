// Module: SparkMessages — Toolbar unread indicator.

import SwiftUI

/// Toolbar unread indicator for the messages screen.
public struct MessagesUnreadToolbarBadge: View {
    let count: Int

    public init(count: Int) {
        self.count = count
    }

    public var body: some View {
        switch count {
        case 0:
            EmptyView()
        default:
            Text(displayText)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.red, in: Capsule())
                .accessibilityLabel(
                    String(localized: "messages.unread.count", defaultValue: "未读消息", comment: "Unread badge")
                )
                .accessibilityValue(displayText)
        }
    }

    private var displayText: String {
        count > 99 ? "99+" : "\(count)"
    }
}

#Preview("Unread badge") {
    MessagesUnreadToolbarBadge(count: 5)
}

#Preview("Unread badge — many") {
    MessagesUnreadToolbarBadge(count: 120)
}
