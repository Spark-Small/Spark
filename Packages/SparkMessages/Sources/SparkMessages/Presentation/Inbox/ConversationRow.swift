// Module: SparkMessages — DM and activity group chat list rows.

import SwiftUI

struct ConversationRow: View {
    let conversation: ConversationPreview

    var body: some View {
        HStack(spacing: 14) {
            leadingAvatar
            VStack(alignment: .leading, spacing: 4) {
                headerLine
                previewLine
                if conversation.kind == .groupChat, let activity = conversation.activity {
                    groupMetaLine(activity: activity)
                }
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var leadingAvatar: some View {
        switch conversation.kind {
        case .dm:
            DMAvatar(
                partner: conversation.dmPartner,
                displayName: conversation.displayName,
                isOnline: conversation.isPartnerOnline ?? false
            )
        case .groupChat:
            GroupChatAvatar(activity: conversation.activity, displayName: conversation.displayName)
        }
    }

    private var headerLine: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(conversation.displayName)
                .font(.headline)
                .foregroundStyle(conversation.hasUnread ? .primary : .primary)
            Spacer(minLength: 8)
            Text(conversation.lastMessageRelativeTime)
                .font(.caption)
                .foregroundStyle(.secondary)
            if conversation.hasUnread {
                UnreadBadge(count: conversation.unreadCount)
            }
        }
    }

    private var previewLine: some View {
        Text(conversation.lastMessagePreview)
            .font(.subheadline)
            .foregroundStyle(conversation.hasUnread ? .primary : .secondary)
            .lineLimit(2)
    }

    private func groupMetaLine(activity: InboxActivitySummary) -> some View {
        HStack(spacing: 6) {
            Text(activity.countdownText)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let members = conversation.memberCount {
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(memberLabel(count: members))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
    }

    private func memberLabel(count: Int) -> String {
        let format = String(
            localized: "messages.group.members.format",
            defaultValue: "%lld 人",
            comment: "Member count"
        )
        return String(format: format, locale: .current, count)
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
        }
    }
}

#Preview("Group conversation row") {
    let inbox = MockMessagesInboxCatalog.inbox(unreadCount: 0)
    List {
        if let group = inbox.activeGroupChats.first {
            ConversationRow(conversation: group)
        }
    }
}
