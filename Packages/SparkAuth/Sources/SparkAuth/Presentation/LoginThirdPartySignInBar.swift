// Module: SparkAuth — Bottom third-party sign-in controls (tab-bar region · TAB_SCREENS L3).

import SparkDesignSystem
import SwiftUI

/// Horizontally arranged circular sign-in buttons pinned above the home indicator.
struct LoginThirdPartySignInBar: View {
    @Bindable var viewModel: AuthViewModel
    let isDisabled: Bool

    var body: some View {
        HStack(spacing: SparkAuthLayoutMetrics.thirdPartySignInSpacing) {
            ForEach(LoginThirdPartySignInKind.loginBarDisplayOrder, id: \.self) { kind in
                LoginThirdPartyCircleButton(
                    kind: kind,
                    isDisabled: isDisabled,
                    action: { Task { await viewModel.thirdPartySignInTapped(kind) } }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, SparkLayoutMetrics.standardHorizontalPadding)
        .padding(.vertical, SparkAuthLayoutMetrics.thirdPartySignInVerticalPadding)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            String(
                localized: "auth.login.thirdParty.group.a11y",
                defaultValue: "其他登录方式",
                comment: "Third-party login button group"
            )
        )
    }
}

private struct LoginThirdPartyCircleButton: View {
    let kind: LoginThirdPartySignInKind
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            label
                .frame(
                    width: SparkAuthLayoutMetrics.thirdPartySignInButtonSize,
                    height: SparkAuthLayoutMetrics.thirdPartySignInButtonSize
                )
                .sparkGlassControl(Circle())
        }
        .buttonStyle(.sparkPressable)
        .disabled(isDisabled)
        .sparkMinimumTouchTarget()
        .accessibilityLabel(kind.accessibilityLabel)
        .accessibilityHint(kind.accessibilityHint)
    }

    @ViewBuilder
    private var label: some View {
        switch kind {
        case .apple:
            Image(systemName: "apple.logo")
                .font(.title3.weight(.semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
        case .alipay:
            Image("AuthLoginAlipay", bundle: .module)
                .resizable()
                .scaledToFit()
                .padding(10)
        case .weChat:
            Image("AuthLoginWeChat", bundle: .module)
                .resizable()
                .scaledToFit()
                .padding(10)
        }
    }
}

private extension LoginThirdPartySignInKind {
    var accessibilityLabel: String {
        switch self {
        case .apple:
            String(localized: "auth.login.thirdParty.apple.a11y", defaultValue: "通过 Apple 登录", comment: "Apple sign in")
        case .alipay:
            String(localized: "auth.login.thirdParty.alipay.a11y", defaultValue: "支付宝登录", comment: "Alipay sign in")
        case .weChat:
            String(localized: "auth.login.thirdParty.weChat.a11y", defaultValue: "微信登录", comment: "WeChat sign in")
        }
    }

    var accessibilityHint: String {
        switch self {
        case .weChat:
            String(
                localized: "auth.login.thirdParty.weChat.hint",
                defaultValue: "使用微信账号登录",
                comment: "WeChat sign in hint"
            )
        case .alipay:
            String(
                localized: "auth.login.thirdParty.alipay.hint",
                defaultValue: "使用支付宝账号登录",
                comment: "Alipay sign in hint"
            )
        case .apple:
            String(
                localized: "auth.login.thirdParty.apple.hint",
                defaultValue: "使用 Apple 账号登录",
                comment: "Apple sign in hint"
            )
        }
    }
}

#if DEBUG
#Preview {
    LoginThirdPartySignInBar(viewModel: AuthPreviewSupport.viewModel(), isDisabled: false)
        .sparkAuthLoginScreenBackground()
}

#Preview("Third-party — Dark") {
    LoginThirdPartySignInBar(viewModel: AuthPreviewSupport.viewModel(), isDisabled: false)
        .sparkAuthLoginScreenBackground()
        .preferredColorScheme(.dark)
}
#endif
