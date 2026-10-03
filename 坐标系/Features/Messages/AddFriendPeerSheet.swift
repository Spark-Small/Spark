//
//  AddFriendPeerSheet.swift
//  坐标系
//
//  陌生人加好友申请 Sheet（系统 Form）。
//

import SwiftUI
import CoordinateModels

struct AddFriendPeerSheet: View {
    let route: AddFriendPeerRoute

    @Environment(MessagesModel.self) private var messages
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var verificationMessage = ""
    @State private var alertTitle: String?
    @State private var alertMessage: String?

    private var quickReplies: [(label: String, text: String)] {
        route.context.quickReplies(
            peerName: route.nickname,
            activities: activities,
            currentUser: app.user
        )
    }

    var body: some View {
        MessagesFormSheet(
            title: MessagesCopy.addFriendPeerTitle,
            dismissAction: .cancel
        ) {
            Form {
                Section {
                    HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                        PlatformListAvatarView(name: route.nickname, side: PlatformConversationListRow.imageSide)
                        Text(route.nickname)
                            .font(.headline)
                    }
                } footer: {
                    Text(MessagesCopy.addFriendVerifyFooter)
                }

                if route.isPending {
                    Section {
                        Label(
                            MessagesCopy.friendRequestPendingDescription,
                            systemImage: "clock"
                        )
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        TextField(
                            MessagesCopy.addFriendVerifyPlaceholder,
                            text: $verificationMessage,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                    } header: {
                        Text(MessagesCopy.addFriendVerifyField)
                    }

                    if !quickReplies.isEmpty {
                        Section(route.context.quickReplySectionTitle) {
                            ForEach(Array(quickReplies.enumerated()), id: \.offset) { _, reply in
                                Button(reply.label) {
                                    verificationMessage = reply.text
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                if !route.isPending {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MessagesCopy.addFriendSend) {
                            submitRequest()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert(alertTitle ?? "", isPresented: Binding(
                get: { alertTitle != nil },
                set: { if !$0 { alertTitle = nil } }
            )) {
                Button("好的", role: .cancel) {
                    alertTitle = nil
                    dismiss()
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func submitRequest() {
        switch messages.sendFriendRequest(to: route.nickname, message: verificationMessage) {
        case .sent:
            alertTitle = MessagesCopy.friendRequestSentTitle
            alertMessage = MessagesCopy.friendRequestSentMessage(route.nickname)
        case .alreadyFriend:
            alertTitle = MessagesCopy.addFriendPeerTitle
            alertMessage = MessagesCopy.addFriendAlreadyFriend(route.nickname)
        case .alreadyPending:
            alertTitle = MessagesCopy.friendRequestPending
            alertMessage = MessagesCopy.friendRequestPendingDescription
        case .invalidName:
            break
        }
    }
}
