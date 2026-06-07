// Module: SparkMessages — Section divider with optional unread count.

import SparkDesignSystem
import SwiftUI

struct InboxSectionHeader: View {
    let title: String
    let systemImage: String
    let unreadCount: Int

    var body: some View {
        HStack(spacing: SparkLayoutMetrics.compactVerticalPadding) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()
            if unreadCount > 0 {
                UnreadBadge(count: unreadCount)
            }
        }
        .textCase(nil)
        .listRowInsets(
            EdgeInsets(
                top: SparkLayoutMetrics.inboxSectionHeaderTopPadding,
                leading: SparkLayoutMetrics.standardHorizontalPadding,
                bottom: SparkLayoutMetrics.inboxSectionHeaderBottomPadding,
                trailing: SparkLayoutMetrics.standardHorizontalPadding
            )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(sectionAccessibilityLabel)
    }

    private var sectionAccessibilityLabel: String {
        if unreadCount > 0 {
            let format = String(
                localized: "messages.section.header.unread.format",
                defaultValue: "%1$@，%2$d 条未读",
                comment: "Section header; title, unread"
            )
            return String(format: format, locale: .current, title, unreadCount)
        }
        return title
    }
}

#Preview("Section header — with unread") {
    List {
        InboxSectionHeader(title: "私信", systemImage: "bubble.left.and.bubble.right", unreadCount: 3)
    }
}

#Preview("Section header — no unread") {
    List {
        InboxSectionHeader(title: "群聊", systemImage: "person.3", unreadCount: 0)
    }
}
