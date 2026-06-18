// Module: SparkAuth — Password reset request screen (system Form).

import SparkDesignSystem
import SwiftUI

public struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        Form {
            emailSection
            if viewModel.passwordResetSent {
                confirmationSection
            }
            submitSection
        }
        .sparkAuthFormChrome()
        .sparkAuthReadableFormWidth()
        .navigationTitle(
            String(localized: "auth.forgotPassword.title", defaultValue: "忘记密码", comment: "Forgot password title")
        )
        .navigationBarTitleDisplayMode(.inline)
        .authFailureAlert(viewModel: viewModel, context: .passwordReset)
    }

    private var emailSection: some View {
        Section {
            TextField(
                String(localized: "auth.login.email", defaultValue: "邮箱", comment: "Email field"),
                text: $viewModel.passwordResetEmail
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.go)
            .sparkAuthFormCredentialRow()
            .onSubmit { Task { await viewModel.requestPasswordResetTapped() } }
        } footer: {
            Text(
                String(
                    localized: "auth.forgotPassword.footer",
                    defaultValue: "若该邮箱已注册，你将收到重置密码的说明。",
                    comment: "Forgot password footer"
                )
            )
        }
    }

    private var confirmationSection: some View {
        Section {
            Label(
                String(
                    localized: "auth.forgotPassword.sent",
                    defaultValue: "重置说明已发送，请查收邮件",
                    comment: "Reset sent"
                ),
                systemImage: "envelope.badge"
            )
            .foregroundStyle(.secondary)
        }
    }

    private var submitSection: some View {
        Section {
            Button {
                Task { await viewModel.requestPasswordResetTapped() }
            } label: {
                Group {
                    if viewModel.isRequestingPasswordReset {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text(
                            String(
                                localized: "auth.forgotPassword.button",
                                defaultValue: "发送重置说明",
                                comment: "Send reset"
                            )
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .disabled(!viewModel.canRequestPasswordReset || viewModel.isRequestingPasswordReset)
            .sparkAuthFormPrimaryRow()
            .sparkMinimumTouchTarget()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthPreviewSupport.viewModel())
    }
}
#endif
