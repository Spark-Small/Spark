// Module: SparkMessages — Collapsed ended activity group chats.

import SparkDesignSystem
import SwiftUI

struct ArchivedChatsDisclosure<Row: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let chats: [ConversationPreview]
    @ViewBuilder let row: (ConversationPreview) -> Row

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(chats) { chat in
                row(chat)
            }
        } label: {
            Text(
                String(
                    localized: "messages.archived.title",
                    defaultValue: "已结束的活动",
                    comment: "Archived group chats"
                )
            )
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
        .onAppear {
            if horizontalSizeClass == .regular {
                isExpanded = true
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "messages.archived.a11y.label",
                defaultValue: "已结束的活动",
                comment: "Archived chats disclosure label"
            )
        )
        .accessibilityValue(
            isExpanded
                ? String(
                    localized: "messages.archived.a11y.expanded",
                    defaultValue: "已展开",
                    comment: "Disclosure expanded"
                )
                : String(
                    localized: "messages.archived.a11y.collapsed",
                    defaultValue: "已折叠",
                    comment: "Disclosure collapsed"
                )
        )
        .accessibilityHint(
            String(
                localized: "messages.archived.a11y.hint",
                defaultValue: "连按两下可展开或折叠",
                comment: "Archived chats disclosure hint"
            )
        )
    }
}

#Preview("Archived chats") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 0)
    NavigationStack {
        List {
            ArchivedChatsDisclosure(chats: inbox.archivedGroupChats) { chat in
                NavigationLink(value: chat.asMessageThread()) {
                    ConversationRow(conversation: chat)
                }
                .sparkFlatTabListRow()
            }
        }
        .sparkFlatTabListStyle()
    }
}

#Preview("Archived chats — iPad expanded") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 0)
    NavigationStack {
        List {
            ArchivedChatsDisclosure(chats: inbox.archivedGroupChats) { chat in
                NavigationLink(value: chat.asMessageThread()) {
                    ConversationRow(conversation: chat)
                }
                .sparkFlatTabListRow()
            }
        }
        .sparkFlatTabListStyle()
    }
    .environment(\.horizontalSizeClass, .regular)
}
