// Module: SparkMessages — DM and activity group chat list rows.

import SparkDesignSystem
import SwiftUI

struct ConversationRow: View {
    let conversation: ConversationPreview
    var isNewMatch: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                leadingAvatar
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(conversation.displayName)
                            .font(.body.weight(conversation.hasUnread ? .semibold : .regular))
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(conversation.lastMessageRelativeTime)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                    previewLine
                }
            }
            .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
            .padding(.vertical, SparkLayoutMetrics.inboxRowVerticalPadding)
            .frame(
                minHeight: SparkLayoutMetrics.inboxConversationRowMinHeight,
                alignment: .center
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)

            Divider()
        }
    }

    @ViewBuilder
    private var leadingAvatar: some View {
        switch conversation.kind {
        case .dm:
            DMAvatar(
                partner: conversation.dmPartner,
                displayName: conversation.displayName,
                isOnline: conversation.isPartnerOnline ?? false,
                unreadCount: conversation.unreadCount
            )
        case .groupChat:
            GroupChatAvatar(
                activity: conversation.activity,
                displayName: conversation.displayName,
                unreadCount: conversation.unreadCount
            )
        }
    }

    private var previewLine: some View {
        Text(conversation.lastMessagePreview)
            .font(.subheadline)
            .foregroundStyle(previewForegroundStyle)
            .fontWeight(isNewMatch ? .semibold : .regular)
            .lineLimit(2)
    }

    private var previewForegroundStyle: Color {
        if isNewMatch {
            return Color.accentColor
        }
        return conversation.hasUnread ? .primary : .secondary
    }

    private var accessibilityLabel: String {
        if conversation.hasUnread {
            let format = String(
                localized: "messages.row.unread.format",
                defaultValue: "未读，%@",
                comment: "Unread row; %@ is message preview"
            )
            return "\(conversation.displayName)，\(String(format: format, locale: .current, conversation.lastMessagePreview))"
        }
        return "\(conversation.displayName)，\(conversation.lastMessagePreview)"
    }
}

#Preview("DM conversation row") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 3)
    List {
        if let dm = inbox.dmConversations.first {
            ConversationRow(conversation: dm)
                .sparkFlatTabListRow()
        }
    }
    .sparkFlatTabListStyle()
}

#Preview("Group conversation row") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 0)
    List {
        if let group = inbox.activeGroupChats.first {
            ConversationRow(conversation: group)
                .sparkFlatTabListRow()
        }
    }
    .sparkFlatTabListStyle()
}

#Preview("New match row") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 1)
    List {
        if let match = inbox.unmessagedMatches.first {
            ConversationRow(
                conversation: MessagesInboxSorting.conversationPreview(from: match),
                isNewMatch: true
            )
            .sparkFlatTabListRow()
        }
    }
    .sparkFlatTabListStyle()
}
