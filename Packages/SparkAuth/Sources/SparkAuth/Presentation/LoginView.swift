// Module: SparkAuth — Login screen (Apple + email).

import AuthenticationServices
import SparkDesignSystem
import SparkPersistence
import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    emailFields
                    signInButton
                    divider
                    appleButton
                }
                .padding(24)
            }
            .navigationTitle(
                String(localized: "auth.login.title", defaultValue: "登录 Spark", comment: "Login title")
            )
            .navigationBarTitleDisplayMode(.large)
            .background(.background)
            .sparkDismissesKeyboardOnScroll()
            .alert(
                String(localized: "auth.login.error.title", defaultValue: "无法登录", comment: "Login error title"),
                isPresented: failureBinding
            ) {
                Button(String(localized: "auth.login.error.ok", defaultValue: "好", comment: "OK")) {
                    viewModel.dismissFailure()
                }
            } message: {
                if case let .failure(message) = viewModel.authState {
                    Text(message)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                String(
                    localized: "auth.login.subtitle",
                    defaultValue: "登录后继续活动与消息",
                    comment: "Login subtitle"
                )
            )
            .font(.title3.weight(.semibold))
#if DEBUG
            Text(
                String(
                    localized: "auth.login.hint",
                    defaultValue: "演示环境可使用任意有效邮箱与 6 位以上密码",
                    comment: "Login hint"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
#endif
        }
    }

    private var emailFields: some View {
        VStack(spacing: 12) {
            TextField(
                String(localized: "auth.login.email", defaultValue: "邮箱", comment: "Email field"),
                text: $viewModel.email
            )
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            SecureField(
                String(localized: "auth.login.password", defaultValue: "密码", comment: "Password field"),
                text: $viewModel.password
            )
            .textContentType(.password)
        }
        .padding(16)
        .sparkGlassSurface(RoundedRectangle.sparkCard)
    }

    private var signInButton: some View {
        Button(
            String(localized: "auth.login.email.button", defaultValue: "邮箱登录", comment: "Email sign in")
        ) {
            Task { await viewModel.signInWithEmailTapped() }
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.email.isEmpty || viewModel.password.count < 6)
    }

    private var divider: some View {
        HStack {
            Rectangle().frame(height: 1).foregroundStyle(.tertiary)
            Text(String(localized: "auth.login.or", defaultValue: "或", comment: "Divider"))
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle().frame(height: 1).foregroundStyle(.tertiary)
        }
    }

    private var appleButton: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            Task { await viewModel.handleAppleSignInResult(result) }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityLabel(
            String(localized: "auth.login.apple", defaultValue: "通过 Apple 登录", comment: "Apple sign in")
        )
    }

    private var failureBinding: Binding<Bool> {
        Binding(
            get: {
                if case .failure = viewModel.authState { return true }
                return false
            },
            set: { isPresented in
                if !isPresented { viewModel.dismissFailure() }
            }
        )
    }
}

#Preview {
    let store = AuthSessionStore()
    let tokenProvider = KeychainAccessTokenProvider()
    let service = MockAuthService(sessionStore: store, tokenProvider: tokenProvider)
    LoginView(viewModel: AuthViewModel(authService: service))
}
