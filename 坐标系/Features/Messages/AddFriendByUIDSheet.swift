//
//  AddFriendByUIDSheet.swift
//  坐标系
//
//  通过对外数字 UID 添加好友。
//

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

    private var canSubmit: Bool {
        UserPublicID.isValid(uidText)
    }

    private var resolvedPreview: UserPublicDirectoryHit? {
        guard UserPublicID.isValid(uidText) else { return nil }
        return UserPublicDirectory.resolve(rawUID: uidText, myUser: app.user)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(MessagesCopy.addFriendByUIDPlaceholder, text: $uidText)
                        .keyboardType(.numberPad)
                        .textContentType(.none)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } header: {
                    Text(MessagesCopy.addFriendByUIDField)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
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

                Section {
                    Button(MessagesCopy.addFriendByUIDAction) {
                        submit()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSubmit)
                }
            }
            .navigationTitle(MessagesCopy.addFriendByUIDTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(MessagesCopy.cancel) { dismiss() }
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
        .platformSheet(.form)
    }

    private func submit() {
        switch model.addFriendByPublicUID(uidText, myUser: app.user) {
        case .added(let nickname, _):
            pendingOpenNickname = nickname
            alertTitle = "已添加"
            alertMessage = MessagesCopy.addFriendByUIDSuccess(nickname)
        case .alreadyFriend(let nickname):
            pendingOpenNickname = nil
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDAlreadyFriend(nickname)
        case .isSelf:
            pendingOpenNickname = nil
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDIsSelf
        case .notFound:
            pendingOpenNickname = nil
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDNotFound
        case .invalid:
            pendingOpenNickname = nil
            alertTitle = "无法添加"
            alertMessage = MessagesCopy.addFriendByUIDInvalid
        }
    }

    private func finishAlert() {
        let nickname = pendingOpenNickname
        alertMessage = nil
        pendingOpenNickname = nil
        if let nickname {
            onAdded?(nickname)
            dismiss()
        }
    }
}
