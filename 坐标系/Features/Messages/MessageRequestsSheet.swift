//
//  MessageRequestsSheet.swift
//  坐标系
//
//  通讯录「好友请求」：仅好友申请（含等待验证）；无陌生人消息、无行副标题。
//  行用 NavigationLink + swipeActions（chrome 在后），避免 Button+swipe 起手闪屏。
//

import SwiftUI
import CoordinateModels

struct MessageRequestsSheet: View {
    @Environment(MessagesModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    var onOpen: (ChatConversation) -> Void

    private var pendingFriendRequests: [FriendRequest] {
        model.friendRequests
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var outgoingPending: [OutgoingFriendRequest] {
        model.outgoingFriendRequests
            .filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var isEmpty: Bool {
        pendingFriendRequests.isEmpty && outgoingPending.isEmpty
    }

    var body: some View {
        MessagesBrowserSheet(title: MessagesCopy.messageRequestsTitle) {
            List {
                if isEmpty {
                    emptyState
                } else {
                    incomingSection
                    outgoingSection
                }
            }
            .navigationDestination(for: FriendRequest.self) { request in
                MessageRequestDecisionView(
                    title: request.fromName,
                    message: request.message,
                    onAccept: { acceptFriendRequest(request) },
                    onDelete: { declineFriendRequest(request.id) }
                )
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(MessagesCopy.messageRequestsEmptyTitle, systemImage: "person.crop.circle.badge.questionmark")
        } description: {
            Text(MessagesCopy.messageRequestsEmptyDescription)
        }
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var incomingSection: some View {
        if !pendingFriendRequests.isEmpty {
            ForEach(pendingFriendRequests) { request in
                NavigationLink(value: request) {
                    PlatformConversationRow(
                        title: request.fromName,
                        time: request.createdAt
                    )
                }
                .navigationLinkIndicatorVisibility(.hidden)
                .accessibilityHint(request.message)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        acceptFriendRequest(request)
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .tint(.accentColor)
                    .accessibilityLabel(MessagesCopy.accept)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        declineFriendRequest(request.id)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel(MessagesCopy.delete)
                }
                .messagesListRow()
            }
        }
    }

    @ViewBuilder
    private var outgoingSection: some View {
        if !outgoingPending.isEmpty {
            Section(MessagesCopy.outgoingFriendRequestsSection) {
                ForEach(outgoingPending) { request in
                    PlatformConversationRow(
                        title: request.toName,
                        time: request.createdAt
                    )
                    .accessibilityValue(MessagesCopy.outgoingFriendRequestPending)
                    .messagesListRow()
                }
            }
        }
    }

    private func declineFriendRequest(_ id: FriendRequest.ID) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            model.declineFriendRequest(id)
        }
    }

    private func acceptFriendRequest(_ request: FriendRequest) {
        let name = request.fromName
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            model.acceptFriendRequest(request.id)
        }
        if let convo = model.conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            dismiss()
            onOpen(convo)
        }
    }
}
