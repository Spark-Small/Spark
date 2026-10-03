//
//  MessageRequestDecisionView.swift
//  坐标系
//
//  好友申请：受限预览 + 顶栏删除 / 接受（陌生人信箱不走本页，直接打开会话）。
//

import SwiftUI
import CoordinateModels

struct MessageRequestDecisionView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let message: String
    var onAccept: () -> Void
    var onDelete: () -> Void

    private var bodyText: String {
        message.isEmpty ? MessagesCopy.messageRequestPreviewEmpty : message
    }

    var body: some View {
        List {
            Section {
                Text(bodyText)
                    .foregroundStyle(message.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .messagesListRow()
            }
        }
        .platformConversationListChrome()
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(MessagesCopy.delete, role: .destructive) {
                    onDelete()
                    dismiss()
                }
                .accessibilityHint(MessagesCopy.ignoreRequestHint)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(MessagesCopy.accept) {
                    onAccept()
                    dismiss()
                }
                .accessibilityHint(MessagesCopy.acceptRequestHint)
            }
        }
    }
}
