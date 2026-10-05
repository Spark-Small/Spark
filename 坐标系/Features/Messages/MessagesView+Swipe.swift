//
//  MessagesView+Swipe.swift
//  坐标系
//
//  收件箱 swipe 对齐系统「邮件」：左 = 未读 / 置顶；右 = 删除 / 免打扰。
//  纯图标 + a11y；删除与「更多」同源走 requestDelete 确认（关闭满滑，避免与 Alert 死锁）。
//

import SwiftUI
import CoordinateModels

extension View {
    func conversationSwipeActions(_ conversation: ChatConversation, model: MessagesModel) -> some View {
        self
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                // 邮件范式：满滑优先「未读 / 已读」
                Button {
                    model.toggleUnread(conversation.id)
                } label: {
                    Image(
                        systemName: conversation.unreadCount > 0
                            ? "envelope.open"
                            : "envelope.badge"
                    )
                }
                .tint(.accentColor)
                .accessibilityLabel(
                    conversation.unreadCount > 0 ? MessagesCopy.markRead : MessagesCopy.markUnread
                )

                Button {
                    model.togglePin(conversation.id)
                } label: {
                    Image(systemName: conversation.isPinned ? "pin.slash" : "pin")
                }
                .tint(.orange)
                .accessibilityLabel(conversation.isPinned ? MessagesCopy.unpin : MessagesCopy.pin)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    model.requestDelete(conversation)
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel(MessagesCopy.delete)

                Button {
                    model.toggleMute(conversation.id)
                } label: {
                    Image(systemName: conversation.isMuted ? "bell" : "bell.slash")
                }
                .tint(.gray)
                .accessibilityLabel(conversation.isMuted ? MessagesCopy.unmute : MessagesCopy.mute)
            }
    }
}
