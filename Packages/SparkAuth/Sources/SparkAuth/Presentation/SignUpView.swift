// Module: SparkAuth — Email registration screen.

import SparkDesignSystem
import SparkPersistence
import SwiftUI

public struct SignUpView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SparkLayoutMetrics.matchCardPadding) {
                fieldsCard
                signUpButton
            }
            .padding(SparkLayoutMetrics.matchCardPadding)
        }
        .background(.background)
        .sparkDismissesKeyboardOnScroll()
        .navigationTitle(
            String(localized: "auth.signUp.title", defaultValue: "注册", comment: "Sign up title")
        )
        .navigationBarTitleDisplayMode(.inline)
    }

    private var fieldsCard: some View {
        VStack(spacing: SparkLayoutMetrics.sectionVerticalPadding) {
            TextField(
                String(localized: "auth.signUp.displayName", defaultValue: "昵称", comment: "Display name"),
                text: $viewModel.signUpDisplayName
            )
            TextField(
                String(localized: "auth.login.email", defaultValue: "邮箱", comment: "Email field"),
                text: $viewModel.signUpEmail
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            SecureField(
                String(localized: "auth.login.password", defaultValue: "密码", comment: "Password field"),
                text: $viewModel.signUpPassword
            )
            .textContentType(.newPassword)

            Text(
                String(
                    localized: "auth.signUp.footer",
                    defaultValue: "密码至少 6 位。注册即表示同意用户协议与隐私政策。",
                    comment: "Sign up footer"
                )
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(SparkLayoutMetrics.standardHorizontalPadding)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    private var signUpButton: some View {
        Button(
            String(localized: "auth.signUp.button", defaultValue: "创建账号", comment: "Sign up button")
        ) {
            Task { await viewModel.signUpWithEmailTapped() }
        }
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .sparkMinimumTouchTarget()
        .disabled(!viewModel.canSignUp)
    }
}

#Preview {
    NavigationStack {
        SignUpView(viewModel: AuthViewModel(authService: MockAuthService(
            sessionStore: AuthSessionStore(),
            tokenProvider: KeychainAccessTokenProvider()
        )))
    }
}
