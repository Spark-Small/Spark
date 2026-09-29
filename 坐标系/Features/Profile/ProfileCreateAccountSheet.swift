//
//  ProfileCreateAccountSheet.swift
//  坐标系
//
//  「我的」创建账号 Sheet。
//

import CoordinateModels
import CoordinateFeatureFlags
import SwiftUI

struct ProfileCreateAccountSheet: View {
    @Bindable var session: LocalAuthSession
    @Environment(\.dismiss) private var dismiss
    /// 弹层说明：交易门槛 / 资料门槛等
    var reason: String = GuestAccessGate.commerceReason

    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var hasAgreedToLegal = false
    @State private var showLegalAlert = false
    @State private var pendingCreateAction: (() -> Void)?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Section("手机号") {
                    LabeledContent("手机号") {
                        TextField("手机号码", text: $phone)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("验证码") {
                        SecureField("输入验证码", text: $code)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.trailing)
                    }
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PlatformStatus.danger)
                    }
                }

                Section {
                    LegalConsentCheckbox(
                        isChecked: $hasAgreedToLegal,
                        showAlert: $showLegalAlert,
                        centersContent: false
                    )
                } footer: {
                    Text("创建账号前需同意用户协议与隐私政策。")
                }

                Section {
                    Button {
                        requireLegalConsent {
                            Task { @MainActor in
                                if let err = await session.signInWithApple() {
                                    errorMessage = err
                                } else if session.isSignedIn, !session.isGuest {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        Label("使用 Apple 创建", systemImage: "apple.logo")
                    }
                    #if DEBUG
                    Button {
                        requireLegalConsent {
                            session.signInDemoWeChat()
                            dismiss()
                        }
                    } label: {
                        Label("使用微信创建（演示）", systemImage: "message")
                    }
                    #endif
                } header: {
                    Text("其他方式")
                } footer: {
                    #if DEBUG
                    Text("Apple 为系统登录；微信演示仅 DEBUG。远程短信验证码由服务端下发。")
                    #else
                    Text("推荐使用 Sign in with Apple 或手机号短信验证码创建账号。")
                    #endif
                }
            }
            .navigationTitle("创建账号")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarVisibility(.hidden, for: .tabBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建账号") {
                        requireLegalConsent(createAccount)
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .legalConsentAlert(
            isPresented: $showLegalAlert,
            onAgree: {
                hasAgreedToLegal = true
                let action = pendingCreateAction
                pendingCreateAction = nil
                action?()
                Task { await PermissionLaunchPrompts.requestTrackingAfterConsentIfNeeded() }
            },
            onReject: {
                pendingCreateAction = nil
            }
        )
        .platformSheet(.form)
    }

    private func requireLegalConsent(_ action: @escaping () -> Void) {
        if hasAgreedToLegal {
            action()
        } else {
            pendingCreateAction = action
            showLegalAlert = true
        }
    }

    private func createAccount() {
        if FeatureFlags.useRemoteAuth {
            Task { @MainActor in
                if let err = await session.signInRemote(phone: phone, code: code) {
                    errorMessage = err
                } else {
                    dismiss()
                }
            }
        } else {
            #if DEBUG
            if session.signIn(phone: phone, code: code) {
                dismiss()
            } else {
                errorMessage = "请输入有效手机号，并使用演示验证码。"
            }
            #else
            errorMessage = "请使用短信验证码创建账号。"
            #endif
        }
    }
}

