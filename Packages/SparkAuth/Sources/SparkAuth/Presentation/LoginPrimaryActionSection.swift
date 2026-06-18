// Module: SparkAuth — Login / cancel Form section (TAB_SCREENS L3).

import SparkDesignSystem
import SwiftUI

struct LoginPrimaryActionSection: View {
    let isSigningIn: Bool
    let isCancelEnabled: Bool
    let isLoginEnabled: Bool
    let onLogin: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Section {
            loginButton
                .sparkAuthFormPrimaryRow()
            cancelButton
                .sparkAuthFormPrimaryRow()
        }
    }

    private var loginButton: some View {
        Button(action: onLogin) {
            Group {
                if isSigningIn {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(
                            String(
                                localized: "auth.login.submit.loading.a11y",
                                defaultValue: "正在登录",
                                comment: "Sign in loading a11y"
                            )
                        )
                } else {
                    Text(
                        String(localized: "auth.login.submit", defaultValue: "登录", comment: "Primary sign in")
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!isLoginEnabled || isSigningIn)
        .sparkMinimumTouchTarget()
        .accessibilityHint(
            String(
                localized: "auth.login.otp.submit.hint",
                defaultValue: "使用手机号与验证码登录",
                comment: "OTP sign in hint"
            )
        )
        .sensoryFeedback(.impact(weight: .medium), trigger: isSigningIn) { _, isLoading in
            isLoading
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
            Text(
                String(localized: "auth.login.cancel", defaultValue: "取消", comment: "Abandon login entry")
            )
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .disabled(!isCancelEnabled)
        .sparkMinimumTouchTarget()
        .accessibilityHint(
            String(
                localized: "auth.login.cancel.hint",
                defaultValue: "清空已输入内容并收起键盘",
                comment: "Login cancel button hint"
            )
        )
    }
}

#if DEBUG
#Preview {
    Form {
        LoginPrimaryActionSection(
            isSigningIn: false,
            isCancelEnabled: true,
            isLoginEnabled: true,
            onLogin: {},
            onCancel: {}
        )
    }
}
#endif
