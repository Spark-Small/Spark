// Module: SparkAuth — Phone OTP password reset screen.

import SparkDesignSystem
import SwiftUI

public struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthPhoneOTPFocusField?

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            subtitleSection
            phoneSection
            if viewModel.passwordResetOTPSent {
                newPasswordSection
            }
            actionSection
        }
        .formStyle(.grouped)
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(ForgotPasswordCopy.title)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: viewModel.passwordResetOTPSent) { _, otpSent in
            guard otpSent else { return }
            focusedField = .verificationCode
        }
        .onDisappear {
            viewModel.clearPasswordResetForm()
        }
        .authFailureAlert(viewModel: viewModel)
    }
}

// MARK: - Sections

private extension ForgotPasswordView {
    var subtitleSection: some View {
        Section {
            Text(ForgotPasswordCopy.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
        }
    }

    var phoneSection: some View {
        Section {
            AuthPhoneOTPFields(
                phone: $viewModel.passwordResetPhone,
                verificationCode: $viewModel.passwordResetVerificationCode,
                focusedField: $focusedField,
                phonePlaceholder: LoginCopy.phonePlaceholder,
                verificationCodePlaceholder: LoginCopy.verificationCodePlaceholder,
                sendCodeAccessibilityLabel: LoginCopy.sendVerificationCode,
                otpSent: viewModel.passwordResetOTPSent,
                showsSendArrow: viewModel.showsPasswordResetArrow,
                isSendingOTP: viewModel.isSendingPasswordResetOTP,
                resendSecondsRemaining: viewModel.passwordResetOTPResendSecondsRemaining,
                isInteractionDisabled: viewModel.isResettingPassword,
                onPhoneChange: { viewModel.passwordResetPhoneDidChange() },
                onVerificationCodeChange: { viewModel.passwordResetVerificationCodeDidChange() },
                onSendOTP: { await viewModel.sendPasswordResetOTPTapped() }
            )
        }
    }

    var newPasswordSection: some View {
        Section {
            SecureField(ForgotPasswordCopy.newPasswordPlaceholder, text: $viewModel.passwordResetNewPassword)
                .textContentType(.newPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .newPassword)
        } footer: {
            Text(ForgotPasswordCopy.newPasswordFooter)
        }
    }

    var actionSection: some View {
        Section {
            Button {
                focusedField = nil
                Task { await viewModel.resetPasswordWithPhoneOTPTapped() }
            } label: {
                Group {
                    if viewModel.isResettingPassword {
                        ProgressView()
                            .controlSize(.regular)
                    } else {
                        Text(ForgotPasswordCopy.confirmButton)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .loginPrimaryButtonChrome()
            .disabled(!viewModel.canResetPasswordWithPhoneOTP)
            .loginActionRowChrome()
        }
    }
}

#Preview("Default") {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthPreviewSupport.makeViewModel())
    }
}

#Preview("OTP sent") {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthPreviewSupport.makeViewModelWithPasswordResetOTPSent())
    }
}
