// Module: SparkMessages — Shared inbox row swipe actions.

import SparkDesignSystem
import SwiftUI

extension View {
    func messagesConversationSwipeActions(
        conversation: ConversationPreview,
        onMarkRead: @escaping () -> Void,
        onHide: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        swipeActions(edge: .trailing, allowsFullSwipe: conversation.hasUnread) {
            if conversation.hasUnread {
                Button(action: onMarkRead) {
                    Label(
                        String(localized: "messages.row.markRead", defaultValue: "标为已读", comment: "Mark read swipe"),
                        systemImage: "envelope.open"
                    )
                }
                .tint(.blue)
            }
            Button(action: onHide) {
                Label(
                    String(localized: "messages.row.hide", defaultValue: "不显示", comment: "Hide conversation swipe"),
                    systemImage: "eye.slash"
                )
            }
            .tint(.gray)
            Button(role: .destructive, action: onDelete) {
                Label(
                    String(localized: "messages.row.delete", defaultValue: "删除", comment: "Delete conversation swipe"),
                    systemImage: "trash"
                )
            }
        }
    }
}
