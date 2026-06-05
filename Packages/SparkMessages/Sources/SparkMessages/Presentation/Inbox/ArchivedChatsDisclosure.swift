// Module: SparkMessages — Collapsed ended activity group chats.

import SwiftUI

struct ArchivedChatsDisclosure: View {
    let chats: [ConversationPreview]

    var body: some View {
        DisclosureGroup {
            ForEach(chats) { chat in
                NavigationLink(value: chat.asMessageThread()) {
                    ConversationRow(conversation: chat)
                }
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
