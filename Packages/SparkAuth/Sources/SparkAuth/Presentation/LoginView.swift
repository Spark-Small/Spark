// Module: SparkAuth — Login screen (phone-first · native Form · CN).

import SparkDesignSystem
import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var isForgotPasswordPresented = false
    @FocusState private var focusedField: LoginFormField?
    /// Optional hook when `LoginView` is presented modally; root shell omits this.
    private let onDismiss: (() -> Void)?

    public init(viewModel: AuthViewModel, onDismiss: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            loginForm
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    LoginThirdPartySignInBar(
                        viewModel: viewModel,
                        isDisabled: !viewModel.canUseThirdPartySignIn
                    )
                }
                .navigationTitle(
                    String(localized: "auth.login.brand", defaultValue: "Nexus", comment: "Login brand name")
                )
                .navigationBarTitleDisplayMode(.large)
                .authFailureAlert(viewModel: viewModel)
                .navigationDestination(isPresented: $isForgotPasswordPresented) {
                    ForgotPasswordView(viewModel: viewModel)
                }
        }
        .sparkAuthLoginScreenBackground()
    }

    private var loginForm: some View {
        Form {
            legalConsentSection
            credentialsSection
            LoginPrimaryActionSection(
                isSigningIn: viewModel.isSigningIn,
                isCancelEnabled: !viewModel.isSigningIn && !viewModel.isRequestingOTP,
                isLoginEnabled: viewModel.canSignInWithOTP,
                onLogin: { Task { await viewModel.signInWithPhoneOTPTapped() } },
                onCancel: cancelLoginTapped
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .onChange(of: viewModel.otpSent) { _, sent in
            if sent { focusedField = .otp }
        }
    }

    // MARK: - Sections

    private func cancelLoginTapped() {
        focusedField = nil
        viewModel.cancelLoginTapped()
        onDismiss?()
    }

    private var legalConsentSection: some View {
        Section {
            LoginLegalConsentSection(
                isAccepted: Binding(
                    get: { viewModel.hasAcceptedLegalTerms },
                    set: { viewModel.setLegalTermsAccepted($0) }
                )
            )
        } footer: {
            Text(
                String(
                    localized: "auth.login.newUser.footer",
                    defaultValue: "未注册手机号验证通过后将自动创建账号",
                    comment: "New user auto-registration note"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }

    private var credentialsSection: some View {
        Section {
            LoginPhoneNumberFieldRow(viewModel: viewModel, focusedField: $focusedField)

            if viewModel.otpSent {
                LoginOTPFieldRow(viewModel: viewModel, focusedField: $focusedField)
            }
        } header: {
            Text(
                String(
                    localized: "auth.login.slogan",
                    defaultValue: "有些关系，从一句你好开始",
                    comment: "Login brand slogan"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .textCase(nil)
        } footer: {
            forgotPasswordLink
        }
    }

    private var forgotPasswordLink: some View {
        Button {
            isForgotPasswordPresented = true
        } label: {
            Text(
                String(
                    localized: "auth.login.forgotPassword",
                    defaultValue: "忘记密码",
                    comment: "Forgot password link"
                )
            )
            .font(.body)
            .foregroundStyle(.tint)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint(
            String(
                localized: "auth.login.forgotPassword.hint",
                defaultValue: "通过邮箱找回密码",
                comment: "Forgot password link hint"
            )
        )
    }
}

#if DEBUG
#Preview("Phone login") {
    LoginView(viewModel: AuthPreviewSupport.viewModel())
}

#Preview("Phone login — OTP expanded") {
    LoginView(viewModel: AuthPreviewSupport.phoneOTPExpandedViewModel())
}

#Preview("Login — Dark") {
    LoginView(viewModel: AuthPreviewSupport.viewModel())
        .preferredColorScheme(.dark)
}

#Preview("Login — Accessibility XL") {
    LoginView(viewModel: AuthPreviewSupport.viewModel())
        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
}

#Preview("Login — Signing in") {
    LoginView(viewModel: AuthPreviewSupport.signingInViewModel())
}

#Preview("Login — Failure") {
    LoginView(viewModel: AuthPreviewSupport.failureViewModel())
}
#endif
