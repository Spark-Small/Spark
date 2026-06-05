// Module: SparkMessages — Collapsed ended activity group chats.

import SwiftUI

struct ArchivedChatsDisclosure<Row: View>: View {
    let chats: [ConversationPreview]
    @ViewBuilder let row: (ConversationPreview) -> Row

    var body: some View {
        DisclosureGroup {
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
            }
        }
    }
}
