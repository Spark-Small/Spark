// Module: SparkAuth — Login screen (phone OTP + Apple).

import SparkCore
import SparkDesignSystem
import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: AuthPhoneOTPFocusField?

    private let onCancel: (() -> Void)?

    public init(viewModel: AuthViewModel, onCancel: (() -> Void)? = nil) {
        self.viewModel = viewModel
        self.onCancel = onCancel
    }

    private var isPresentedModally: Bool { onCancel != nil }

    public var body: some View {
        SparkScreenContainer(
            navigationTitle: LoginCopy.navigationTitle,
            titleDisplayMode: isPresentedModally ? .inline : .large
        ) {
            Form {
                subtitleSection
                phoneCredentialsSection
                phoneLoginActionsSection
                appleSignInSection
                legalSection
            }
            .formStyle(.grouped)
            .sparkDismissesKeyboardOnScroll()
            .toolbar { loginToolbar }
            .authFailureAlert(viewModel: viewModel)
        }
        .presentationDragIndicator(isPresentedModally ? .visible : .automatic)
    }
}

// MARK: - Sections

private extension LoginView {
    var subtitleSection: some View {
        Section {
            Text(LoginCopy.subtitle)
                .font(.title2.weight(.semibold))
                .accessibilityAddTraits(.isHeader)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
                .listRowBackground(Color.clear)
        }
    }

    var phoneCredentialsSection: some View {
        Section {
            AuthPhoneOTPFields(
                phone: $viewModel.loginPhone,
                verificationCode: $viewModel.loginVerificationCode,
                focusedField: $focusedField,
                phonePlaceholder: LoginCopy.phonePlaceholder,
                verificationCodePlaceholder: LoginCopy.verificationCodePlaceholder,
                sendCodeAccessibilityLabel: LoginCopy.sendVerificationCode,
                otpSent: viewModel.loginOTPSent,
                showsSendArrow: viewModel.showsPhoneLoginArrow,
                isSendingOTP: viewModel.isSendingLoginOTP,
                resendSecondsRemaining: viewModel.loginOTPResendSecondsRemaining,
                isInteractionDisabled: viewModel.isSignInInProgress,
                onPhoneChange: { viewModel.loginPhoneDidChange() },
                onVerificationCodeChange: { viewModel.loginVerificationCodeDidChange() },
                onSendOTP: { await viewModel.sendLoginPhoneOTPTapped() }
            )
        } footer: {
            NavigationLink {
                ForgotPasswordView(viewModel: viewModel)
            } label: {
                Text(LoginCopy.forgotPassword)
                    .font(.footnote)
            }
            .accessibilityHint(LoginCopy.forgotPasswordHint)
        }
        .onChange(of: viewModel.loginOTPSent) { _, otpSent in
            guard otpSent else { return }
            focusedField = .verificationCode
        }
        .onChange(of: viewModel.loginVerificationCode) { _, _ in
            guard viewModel.shouldAutoSubmitLoginOTP else { return }
            focusedField = nil
            Task { await viewModel.signInWithPhoneOTPTapped() }
        }
    }

    var phoneLoginActionsSection: some View {
        Section {
            VStack(spacing: SparkAuthLayout.signInButtonSpacing) {
                Button {
                    focusedField = nil
                    Task { await viewModel.signInWithPhoneOTPTapped() }
                } label: {
                    Group {
                        if viewModel.isLoading(for: .phoneOtp) {
                            ProgressView()
                                .controlSize(.regular)
                        } else {
                            Text(LoginCopy.signIn)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .loginPrimaryButtonChrome()
                .disabled(!viewModel.canSignInWithPhoneOTP)

                if showsFlowCancelButton {
                    Button(role: .cancel, action: cancelLoginFlow) {
                        Text(LoginCopy.cancel)
                            .frame(maxWidth: .infinity)
                    }
                    .loginSecondaryButtonChrome()
                    .disabled(viewModel.isSignInInProgress)
                    .accessibilityHint(LoginCopy.cancelHint)
                }
            }
            .loginActionRowChrome()
        }
    }

    var appleSignInSection: some View {
        Section {
            Button {
                focusedField = nil
                Task { await viewModel.signInWithAppleTapped() }
            } label: {
                Group {
                    if viewModel.isLoading(for: .apple) {
                        ProgressView()
                            .controlSize(.regular)
                            .tint(AuthBrandColor.appleSignInForeground(for: colorScheme))
                    } else {
                        Label(LoginCopy.appleSignIn, systemImage: "apple.logo")
                            .font(.body.weight(.semibold))
                            .labelStyle(.titleAndIcon)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .loginAppleSignInButtonChrome(colorScheme: colorScheme)
            .disabled(viewModel.isSignInInProgress)
            .opacity(viewModel.isLoading(for: .apple) ? 0.65 : 1)
            .accessibilityLabel(LoginCopy.appleSignIn)
            .loginActionRowChrome()
        }
    }

    var legalSection: some View {
        Section {
            AuthLegalFooter()
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .listRowInsets(SparkAuthLayout.legalRowInsets)
                .listRowBackground(Color.clear)
        }
    }
}

// MARK: - Toolbar

private extension LoginView {
    @ToolbarContentBuilder
    var loginToolbar: some ToolbarContent {
        if isPresentedModally {
            ToolbarItem(placement: .cancellationAction) {
                Button(LoginCopy.cancel, role: .cancel, action: cancelLoginFlow)
                    .disabled(viewModel.isSignInInProgress)
            }
        }
    }

    var showsFlowCancelButton: Bool {
        viewModel.loginOTPSent
            || !viewModel.loginPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func cancelLoginFlow() {
        focusedField = nil
        viewModel.cancelPhoneLoginTapped()
        onCancel?()
    }
}

// MARK: - Previews

#Preview("Light") {
    LoginView(viewModel: AuthPreviewSupport.makeViewModel())
}

#Preview("Dark") {
    SparkPreviewSupport.darkMode {
        LoginView(viewModel: AuthPreviewSupport.makeViewModel())
    }
}

#Preview("Accessibility XL") {
    SparkPreviewSupport.accessibilityXL {
        LoginView(viewModel: AuthPreviewSupport.makeViewModel())
    }
}

#Preview("OTP sent") {
    LoginView(viewModel: AuthPreviewSupport.makeViewModelWithOTPSent())
}

#Preview("Modal") {
    LoginView(viewModel: AuthPreviewSupport.makeViewModel(), onCancel: {})
}
