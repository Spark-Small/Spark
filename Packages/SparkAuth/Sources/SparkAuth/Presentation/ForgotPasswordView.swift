// Module: SparkAuth — Password reset request screen.

import SparkDesignSystem
import SparkPersistence
import SwiftUI

public struct ForgotPasswordView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.matchCardPadding) {
                fieldsCard
                if viewModel.passwordResetSent {
                    sentConfirmation
                }
                resetButton
            }
            .padding(SparkLayoutMetrics.matchCardPadding)
        }
        .background(.background)
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(
            String(localized: "auth.forgotPassword.title", defaultValue: "找回密码", comment: "Forgot password title")
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fieldsCard: some View {
        VStack(alignment: .leading, spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            TextField(
                String(localized: "auth.login.email", defaultValue: "邮箱", comment: "Email field"),
                text: $viewModel.passwordResetEmail
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            Text(
                String(
                    localized: "auth.forgotPassword.footer",
                    defaultValue: "若该邮箱已注册，你将收到重置密码的说明。",
                    comment: "Forgot password footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    private var sentConfirmation: some View {
        Label(
            String(
                localized: "auth.forgotPassword.sent",
                defaultValue: "重置说明已发送，请查收邮件",
                comment: "Reset sent"
            ),
            systemImage: "envelope.badge"
        )
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    private var resetButton: some View {
        Button(
            String(
                localized: "auth.forgotPassword.button",
                defaultValue: "发送重置说明",
                comment: "Send reset"
            )
        ) {
            Task { await viewModel.requestPasswordResetTapped() }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .sparkMinimumTouchTarget()
        .disabled(!viewModel.canRequestPasswordReset || viewModel.isRequestingPasswordReset)
    }
}

#Preview {
    NavigationStack {
        ForgotPasswordView(viewModel: AuthViewModel(authService: MockAuthService(
            sessionStore: AuthSessionStore(),
            tokenProvider: KeychainAccessTokenProvider()
        )))
    }
}
