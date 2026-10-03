//
//  ConversationMessageRow.swift
//  坐标系
//
//  会话详情：单条气泡与上下文菜单（编辑 / 撤回 / 转发 / 删除）。
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
    var onEdit: () -> Void
    var onUnsend: () -> Void
    var onForward: () -> Void
    var onOpenActivity: (UUID) -> Void
    var onOpenLink: (String) -> Void
    var onRetrySend: () -> Void
    var onSetReaction: (String?) -> Void
    var onDelete: () -> Void
    var onCopied: () -> Void

    private var canEdit: Bool {
        message.isMe
            && !message.isSystem
            && !message.isRecalled
            && message.messageKind == .text
            && Date().timeIntervalSince(message.sentAt) <= MessagingDeliveryPolicy.localEditWindow
    }

    private var canUnsend: Bool {
        message.isMe
            && !message.isSystem
            && !message.isRecalled
            && Date().timeIntervalSince(message.sentAt) <= MessagingDeliveryPolicy.localUnsendWindow
    }

    private var canForward: Bool {
        !message.isSystem
            && !message.isRecalled
            && conversationKind != .notice
            && message.messageKind != .transfer
    }

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
            if !message.isRecalled {
                Button(MessagesCopy.copy, systemImage: "doc.on.doc") {
                    UIPasteboard.general.string = message.previewText
                    onCopied()
                }
            }
            if conversationKind != .notice, !message.isRecalled {
                Button(MessagesCopy.reply, systemImage: "arrowshape.turn.up.left") {
                    onReply()
                }
                if canForward {
                    Button(MessagesCopy.forwardMessage, systemImage: "arrowshape.turn.up.forward") {
                        onForward()
                    }
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
            if canEdit {
                Button(MessagesCopy.editMessage, systemImage: "pencil") {
                    onEdit()
                }
            }
            if canUnsend {
                Button(MessagesCopy.unsendMessage, systemImage: "arrow.uturn.backward", role: .destructive) {
                    onUnsend()
                }
            }
            if message.isMe, !message.isRecalled {
                Button(MessagesCopy.deleteMessage, systemImage: "trash", role: .destructive) {
                    onDelete()
                }
            }
        }
    }
}
