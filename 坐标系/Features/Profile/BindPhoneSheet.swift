//
//  BindPhoneSheet.swift
//  坐标系
//
//  已登录用户绑定手机号：短信验证码 → 写入会话（保留原登录方式）。
//

import CoordinateFeatureFlags
import SwiftUI

struct BindPhoneSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var draft = LoginPhoneCodeDraft()
    @State private var isBusy = false
    @State private var feedback: String?

    private var hasBoundPhone: Bool { app.auth.hasBoundPhone }

    var body: some View {
        NavigationStack {
            Form {
                if hasBoundPhone {
                    Section {
                        LabeledContent(
                            EditProfileCopy.phoneLabel,
                            value: app.auth.maskedPhoneLabel
                        )
                    } footer: {
                        Text(EditProfileCopy.phoneBoundFooter)
                    }
                }

                Section {
                    TextField(LoginAuthCopy.phone, text: $draft.phone)
                        .platformCredentialTextInput(.phone)
                        .onChange(of: draft.phone) { _, _ in
                            draft.applySanitizedPhone()
                        }
                    HStack {
                        TextField(LoginAuthCopy.code, text: $draft.code)
                            .platformCredentialTextInput(.oneTimeCode)
                            .onChange(of: draft.code) { _, _ in
                                draft.applySanitizedCode()
                            }
                        Button(draft.sendCodeTitle) {
                            Task { await sendCode() }
                        }
                        .disabled(!draft.canSendCode(isBusy: isBusy))
                    }
                } header: {
                    Text(
                        hasBoundPhone
                            ? EditProfileCopy.phoneRebindHeader
                            : EditProfileCopy.phoneBindHeader
                    )
                } footer: {
                    Text(EditProfileCopy.phoneBindFooter)
                }

                Section {
                    Button {
                        Task { await confirmBind() }
                    } label: {
                        if isBusy {
                            ProgressView()
                        } else {
                            Text(EditProfileCopy.phoneBindConfirm)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(
                        isBusy
                            || !LoginChrome.isValidPhone(draft.phone)
                            || !LoginChrome.isValidCode(draft.code)
                    )
                }
            }
            .navigationTitle(EditProfileCopy.phoneBindTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(EditProfileCopy.back) { dismiss() }
                }
            }
            .platformFeedbackAlert($feedback)
            .disabled(isBusy)
        }
        .platformSheet(.form)
    }

    @MainActor
    private func sendCode() async {
        guard draft.canSendCode(isBusy: isBusy) else { return }
        isBusy = true
        defer { isBusy = false }
        let phone = draft.sanitizedPhone
        if FeatureFlags.useRemoteAuth {
            if let error = await app.auth.sendRemoteSMSCode(
                phone: phone,
                source: .bindPhone
            ) {
                feedback = error
                return
            }
            draft.markCodeSent(to: phone)
            feedback = LoginAuthCopy.codeSent
        } else {
            draft.markCodeSent(to: phone)
            feedback = EditProfileCopy.phoneDemoCodeHint
        }
    }

    @MainActor
    private func confirmBind() async {
        isBusy = true
        defer { isBusy = false }
        if let error = await app.auth.bindPhone(
            phone: draft.sanitizedPhone,
            code: LoginChrome.sanitizedCode(draft.code),
            source: .bindPhone
        ) {
            feedback = error
            return
        }
        feedback = EditProfileCopy.phoneBindSuccess
        dismiss()
    }
}
