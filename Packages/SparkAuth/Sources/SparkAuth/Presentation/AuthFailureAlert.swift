// Module: SparkAuth — Shared auth failure alert for login / password-reset flows.

import SwiftUI

enum AuthFailureAlertContext {
    case login
    case passwordReset

    var title: String {
        switch self {
        case .login:
            String(localized: "auth.login.error.title", defaultValue: "无法登录", comment: "Login error title")
        case .passwordReset:
            String(
                localized: "auth.forgotPassword.error.title",
                defaultValue: "无法发送重置说明",
                comment: "Password reset error title"
            )
        }
    }
}

extension View {
    /// Presents a localized alert when `AuthViewModel.authState` is `.failure`.
    func authFailureAlert(viewModel: AuthViewModel, context: AuthFailureAlertContext = .login) -> some View {
        alert(context.title, isPresented: authFailureBinding(viewModel: viewModel)) {
            Button(String(localized: "auth.login.error.ok", defaultValue: "好", comment: "OK")) {
                viewModel.dismissFailure()
            }
        } message: {
            if case let .failure(message) = viewModel.authState {
                Text(message)
            }
        }
    }

    private func authFailureBinding(viewModel: AuthViewModel) -> Binding<Bool> {
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
