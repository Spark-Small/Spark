//
//  AddFriendByUIDSheet.swift
//  坐标系
//
//  通过对外数字 UID 添加好友（MessagesFormSheet + 系统 Form）。
//

import CoordinateModels
import SwiftUI

struct AddFriendByUIDSheet: View {
    var onAdded: ((String) -> Void)?

    @Environment(MessagesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var uidText = ""
    @State private var alertTitle = ""
    @State private var alertMessage: String?
    @State private var pendingOpenNickname: String?
    @State private var shouldDismissAfterAlert = false

    private var canSubmit: Bool {
        UserPublicID.isValid(uidText)
    }

    private var resolvedPreview: UserPublicDirectoryHit? {
        guard UserPublicID.isValid(uidText) else { return nil }
        return UserPublicDirectory.resolve(rawUID: uidText, myUser: app.user)
    }

    var body: some View {
        MessagesFormSheet(
            title: MessagesCopy.addFriendByUIDTitle,
            dismissAction: .cancel
        ) {
            Form {
                Section {
                    TextField(MessagesCopy.addFriendByUIDPlaceholder, text: $uidText)
                        .platformFormTextInput(.digits)
                } header: {
                    Text(MessagesCopy.addFriendByUIDField)
                } footer: {
                    VStack(alignment: .leading, spacing: PlatformMessagesChrome.stackSpacing) {
                        Text(MessagesCopy.addFriendByUIDFooter)
                        Text("我的 UID：\(app.user.publicUIDDisplay)")
                    }
                }

                if let preview = resolvedPreview, !preview.isSelf {
                    Section("将添加") {
                        LabeledContent("昵称", value: preview.nickname)
                        LabeledContent("UID", value: UserPublicID.formatDisplay(preview.uid))
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(MessagesCopy.addFriendByUIDAction) {
                        submit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
                }
            }
            .alert(
                alertTitle,
                isPresented: Binding(
                    get: { alertMessage != nil },
                    set: { if !$0 { finishAlert() } }
                )
            ) {
                Button("好的", role: .cancel) {
                    finishAlert()
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func submit() {
        switch model.addFriendByPublicUID(uidText, myUser: app.user) {
        case .requestSent(let nickname, _):
            pendingOpenNickname = nil
            shouldDismissAfterAlert = true
            alertTitle = "申请已发送"
            alertMessage = MessagesCopy.addFriendByUIDSuccess(nickname)
        case .alreadyFriend(let nickname):
            // 已是好友：关掉 Sheet 后打开私聊。
            pendingOpenNickname = nickname
            shouldDismissAfterAlert = true
            alertTitle = "已是好友"
            alertMessage = MessagesCopy.addFriendByUIDAlreadyFriend(nickname)
        case .alreadyPending(let nickname):
            pendingOpenNickname = nil
            shouldDismissAfterAlert = false
            alertTitle = "申请处理中"
            alertMessage = MessagesCopy.addFriendByUIDPending(nickname)
        case .isSelf:
            pendingOpenNickname = nil
            shouldDismissAfterAlert = false
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDIsSelf
        case .notFound:
            pendingOpenNickname = nil
            shouldDismissAfterAlert = false
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDNotFound
        case .invalid:
            pendingOpenNickname = nil
            shouldDismissAfterAlert = false
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDInvalid
        }
    }

    private func finishAlert() {
        let nickname = pendingOpenNickname
        let dismissSheet = shouldDismissAfterAlert
        alertMessage = nil
        pendingOpenNickname = nil
        shouldDismissAfterAlert = false
        if let nickname {
            onAdded?(nickname)
        }
        if dismissSheet {
            dismiss()
        }
    }
}
