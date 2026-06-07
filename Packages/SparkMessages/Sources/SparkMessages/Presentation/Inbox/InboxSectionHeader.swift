// Module: SparkMessages — Section divider with optional unread count.

import SwiftUI

struct InboxSectionHeader: View {
    let title: String
    let systemImage: String
    let unreadCount: Int

    var body: some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            if unreadCount > 0 {
                UnreadBadge(count: unreadCount)
            }
        }
        .textCase(nil)
        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 4, trailing: 16))
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
        InboxSectionHeader(title: "活动群聊", systemImage: "person.3", unreadCount: 0)
    }
}
