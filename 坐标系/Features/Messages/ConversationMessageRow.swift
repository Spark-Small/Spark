//
//  ConversationMessageRow.swift
//  坐标系
//
//  会话详情：单条气泡与上下文菜单（独立 View，便于 Preview）。
//

import SwiftUI
import UIKit
import CoordinateModels

struct ConversationMessageRow: View {
    let message: ChatMessage
    let chrome: PlatformChatBubbleChrome
    let conversationKind: ChatKind
    let currentUserName: String
    var onTapAvatar: () -> Void
    var onToggleLike: () -> Void
    var onReply: () -> Void
    var onOpenActivity: (UUID) -> Void
    var onOpenLink: (String) -> Void
    var onRetrySend: () -> Void
    var onSetReaction: (String?) -> Void
    var onDelete: () -> Void
    var onCopied: () -> Void

    var body: some View {
        PlatformChatBubble(
            text: message.text,
            sentAt: message.sentAt,
            sender: message.isMe ? currentUserName : message.sender,
            isMe: message.isMe,
            chrome: chrome,
            message: message,
            isLiked: message.isLiked,
            replyToSender: message.replyToSender,
            replyToText: message.replyToText,
            onTapAvatar: onTapAvatar,
            onDoubleTap: {
                guard conversationKind != .notice else { return }
                onToggleLike()
            },
            onOpenActivity: onOpenActivity,
            onOpenLink: onOpenLink,
            onRetrySend: onRetrySend
        )
        .contextMenu {
            Button(MessagesCopy.copy, systemImage: "doc.on.doc") {
                UIPasteboard.general.string = message.previewText
                onCopied()
            }
            if conversationKind != .notice {
                Button(MessagesCopy.reply, systemImage: "arrowshape.turn.up.left") {
                    onReply()
                }
                Button(
                    message.isLiked ? MessagesCopy.unlike : MessagesCopy.like,
                    systemImage: message.isLiked ? "heart.slash" : "heart"
                ) {
                    onToggleLike()
                }
                Menu(MessagesCopy.reactionMenu) {
                    ForEach(["❤️", "👍", "😂", "😮", "😢"], id: \.self) { emoji in
                        Button(emoji) { onSetReaction(emoji) }
                    }
                    if message.reaction != nil {
                        Button(MessagesCopy.clearReaction, role: .destructive) {
                            onSetReaction(nil)
                        }
                    }
                }
            }
            if message.isMe {
                Button(MessagesCopy.deleteMessage, systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}

#Preview("气泡行") {
    ConversationMessageRow(
        message: ChatMessage(
            id: UUID(),
            sender: "小明",
            text: "今晚见！",
            sentAt: .now,
            isMe: false
        ),
        chrome: PlatformChatBubbleChrome(
            showsSenderName: false,
            showsLeadingAvatar: true,
            showsTrailingAvatar: false,
            reservesLeadingAvatar: true,
            reservesTrailingAvatar: false,
            isClusterContinuation: false,
            isNotice: false
        ),
        conversationKind: .direct,
        currentUserName: "我",
        onTapAvatar: {},
        onToggleLike: {},
        onReply: {},
        onOpenActivity: { _ in },
        onOpenLink: { _ in },
        onRetrySend: {},
        onSetReaction: { _ in },
        onDelete: {},
        onCopied: {}
    )
    .padding()
}
