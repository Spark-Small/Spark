//
//  StrangerMailboxSheet.swift
//  坐标系
//
//  消息 Tab「陌生人信箱」：陌生人发来的聊天会话（非好友申请）。
//  点进打开会话线程；滑动可移入收件箱或删除。好友申请见通讯录「好友请求」。
//

import SwiftUI
import CoordinateModels

struct StrangerMailboxSheet: View {
    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var onOpen: (ChatConversation) -> Void

    private var threads: [ChatConversation] {
        model.strangerMailboxConversations
    }

    var body: some View {
        MessagesBrowserSheet(title: MessagesCopy.strangerMailboxTitle) {
            List {
                if threads.isEmpty {
                    ContentUnavailableView {
                        Label(
                            MessagesCopy.strangerMailboxEmptyTitle,
                            systemImage: "tray"
                        )
                    } description: {
                        Text(MessagesCopy.strangerMailboxEmptyDescription)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityElement(children: .combine)
                } else {
                    ForEach(threads) { conversation in
                        Button {
                            openThread(conversation)
                        } label: {
                            PlatformConversationRow(
                                title: conversation.title,
                                subtitle: conversation.inboxListSecondary,
                                time: conversation.updatedAt,
                                isUnread: conversation.unreadCount > 0
                            )
                        }
                        .buttonStyle(.plain)
                        .messagesListRow()
                        .accessibilityHint(MessagesCopy.strangerMailboxOpenHint)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                moveToInbox(conversation)
                            } label: {
                                Image(systemName: "tray.and.arrow.down")
                            }
                            .tint(.accentColor)
                            .accessibilityLabel(MessagesCopy.strangerMailboxMoveToInbox)
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                model.declineMessageRequest(conversation.id)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .accessibilityLabel(MessagesCopy.strangerMailboxDelete)
                        }
                    }
                }
            }
        }
    }

    private func openThread(_ conversation: ChatConversation) {
        dismiss()
        onOpen(conversation)
    }

    private func moveToInbox(_ conversation: ChatConversation) {
        model.acceptMessageRequest(conversation.id)
        dismiss()
        onOpen(conversation)
    }
}
