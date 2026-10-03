//
//  MessageForwardPickerSheet.swift
//  坐标系
//
//  转发目标选择（本机会话列表）。
//

import SwiftUI
import CoordinateModels

struct MessageForwardPickerSheet: View {
    let source: ChatMessage
    let excludeConversationID: ChatConversation.ID
    var onForwarded: () -> Void

    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    private var destinations: [ChatConversation] {
        model.conversations.filter {
            $0.id != excludeConversationID
                && !$0.isMessageRequest
                && $0.kind != .notice
        }
    }

    var body: some View {
        MessagesBrowserSheet(title: MessagesCopy.forwardPickerTitle, dismissAction: .cancel) {
            List {
                if destinations.isEmpty {
                    ContentUnavailableView {
                        Label(MessagesCopy.forwardEmptyTitle, systemImage: "bubble.left.and.bubble.right")
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(destinations) { conversation in
                        Button {
                            if model.forwardMessage(source, to: conversation.id) != nil {
                                onForwarded()
                                dismiss()
                            }
                        } label: {
                            PlatformConversationRow(
                                title: conversation.title,
                                subtitle: conversation.inboxListSecondary,
                                time: conversation.updatedAt
                            )
                        }
                        .buttonStyle(.plain)
                        .messagesListRow()
                    }
                }
            }
        }
    }
}
