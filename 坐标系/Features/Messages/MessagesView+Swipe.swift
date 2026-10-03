//
//  MessagesView+Swipe.swift
//  坐标系
//
//  收件箱 swipe 对齐系统「邮件」：左 = 未读 / 置顶；右 = 删除 / 免打扰。
//  纯图标 + a11y；满滑删除立即生效（不弹确认，避免与 swipe 动画死锁）。
//  需确认的删除仍走会话「更多」→ requestDelete。
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
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                // 信息 / 邮件：满滑删除立即移除，不在此弹 Alert
                Button(role: .destructive) {
                    model.delete(conversation.id)
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
