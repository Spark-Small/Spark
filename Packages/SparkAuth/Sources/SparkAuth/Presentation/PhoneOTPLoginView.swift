// Module: SparkAuth — Phone OTP login / register flow.

import SparkDesignSystem
import SparkPersistence
import SwiftUI

public struct PhoneOTPLoginView: View {
    @Bindable var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var phone: String = ""
    @State private var code: String = ""
    @State private var isSendingCode = false
    @State private var localErrorMessage: String?

    public init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(
                        String(
                            localized: "auth.login.phoneOtp.subtitle",
                            defaultValue: "通过短信验证码完成登录/注册",
                            comment: "Phone OTP subtitle"
                        )
                    )
                    .font(.title3.weight(.semibold))

                    Text(
                        String(
                            localized: "auth.login.phoneOtp.hint",
                            defaultValue: "首次验证成功后将自动注册为 Spark 用户。",
                            comment: "Phone OTP hint"
                        )
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    phoneField
                    codeField

                    if let localErrorMessage {
                        Text(localErrorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .accessibilityLabel(localErrorMessage)
                    }

                    sendCodeButton
                    verifyButton
                }
                .padding(24)
                .sparkReadableWidth()
            }
            .navigationTitle(
                String(
                    localized: "auth.login.phoneOtp",
                    defaultValue: "手机号验证码登录",
                    comment: "Phone OTP navigation title"
                )
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(
                        String(localized: "common.cancel", defaultValue: "取消", comment: "Cancel")
                    ) {
                        dismiss()
                    }
                    .disabled(authViewModel.isSignInInProgress)
                }
            }
        }
    }

    private var phoneField: some View {
        TextField(
            String(localized: "auth.login.phoneOtp.phone.placeholder", defaultValue: "手机号码", comment: "Phone placeholder"),
            text: $phone
        )
        .keyboardType(.phonePad)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .textContentType(.telephoneNumber)
        .accessibilityLabel(String(localized: "auth.login.phoneOtp.phone", defaultValue: "手机号码", comment: "Phone field label"))
    }

    private var codeField: some View {
        TextField(
            String(localized: "auth.login.phoneOtp.code.placeholder", defaultValue: "验证码", comment: "Code placeholder"),
            text: $code
        )
        .keyboardType(.numberPad)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
        .textContentType(.oneTimeCode)
        .accessibilityLabel(String(localized: "auth.login.phoneOtp.code", defaultValue: "验证码", comment: "Code field label"))
    }

    private var sendCodeButton: some View {
        SparkSignInButton(
            title: String(localized: "auth.login.phoneOtp.sendCode", defaultValue: "发送验证码", comment: "Send code"),
            systemImage: "bolt.circle",
            prominence: .secondary,
            isLoading: isSendingCode,
            isDisabled: isSendingCode || authViewModel.isSignInInProgress,
            accessibilityHint: String(localized: "auth.login.phoneOtp.sendCode.hint", defaultValue: "向手机发送短信验证码", comment: "Send code hint")
        ) {
            Task {
                localErrorMessage = nil
                let normalizedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalizedPhone.count >= 8 else {
                    localErrorMessage = AuthError.invalidCredentials.errorDescription ?? "Invalid phone"
                    return
                }
                isSendingCode = true
                defer { isSendingCode = false }
                do {
                    try await authViewModel.sendPhoneOTP(normalizedPhone)
                } catch {
                    localErrorMessage = (error as? AuthError)?.errorDescription ?? error.localizedDescription
                }
            }
        }
    }

    private var verifyButton: some View {
        SparkSignInButton(
            title: String(localized: "auth.login.phoneOtp.verify", defaultValue: "验证并登录", comment: "Verify and sign in"),
            systemImage: "arrow.right.circle",
            prominence: .primary,
            isLoading: authViewModel.isLoading(for: .phoneOtp),
            isDisabled: authViewModel.isSignInInProgress || isSendingCode,
            accessibilityHint: String(
                localized: "auth.login.phoneOtp.verify.hint",
                defaultValue: "验证验证码并完成登录/注册",
                comment: "Verify code hint"
            )
        ) {
            Task {
                localErrorMessage = nil
                let normalizedPhone = phone.trimmingCharacters(in: .whitespacesAndNewlines)
                let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
                guard normalizedPhone.count >= 8, normalizedCode.count >= 4 else {
                    localErrorMessage = AuthError.invalidCredentials.errorDescription ?? "Invalid code"
                    return
                }
                await authViewModel.signInWithPhoneOTP(phone: normalizedPhone, code: normalizedCode)
                if authViewModel.isAuthenticated {
                    dismiss()
                } else if case let .failure(message) = authViewModel.authState {
                    localErrorMessage = message
                }
            }
        }
    }
}

#Preview("Phone OTP") {
    let store = AuthSessionStore()
    let tokenProvider = KeychainAccessTokenProvider()
    let service = MockAuthService(sessionStore: store, tokenProvider: tokenProvider)
    PhoneOTPLoginView(authViewModel: AuthViewModel(authService: service, cnCoordinators: .preview))
}
