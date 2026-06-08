// Module: SparkAuth — Login screen (WeChat, phone one-tap, Alipay, Apple).

import AuthenticationServices
import SparkDesignSystem
import SwiftUI

public struct LoginView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isPresentingPhoneOTP = false

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        SparkScreenContainer(
            navigationTitle: String(
                localized: "auth.login.title",
                defaultValue: "登录 Spark",
                comment: "Login title"
            )
        ) {
            ScrollView {
                VStack(alignment: .leading, spacing: SparkAuthLayout.sectionSpacing) {
                    header
                    cnSignInButtons
                    orDivider
                    appleButton
                }
                .padding(SparkAuthLayout.screenHorizontalPadding)
                .sparkReadableWidth()
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Color(.systemGroupedBackground))
            .alert(
                String(
                    localized: "auth.login.error.title",
                    defaultValue: "无法登录",
                    comment: "Login error title"
                ),
                isPresented: failureAlertIsPresented
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
        .sheet(isPresented: $isPresentingPhoneOTP) {
            PhoneOTPLoginView(authViewModel: viewModel)
        }
    }

    private var failureAlertIsPresented: Binding<Bool> {
        Binding(
            get: {
                if isPresentingPhoneOTP { return false }
                return viewModel.failureAlertIsPresented.wrappedValue
            },
            set: { isPresented in
                if !isPresented { viewModel.dismissFailure() }
            }
        )
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
            Text(
                String(
                    localized: "auth.login.cn.hint",
                    defaultValue: "推荐使用微信或手机号验证码登录",
                    comment: "Login hint for CN users"
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }

    private var cnSignInButtons: some View {
        VStack(spacing: SparkAuthLayout.signInButtonSpacing) {
            cnSignInButton(
                title: String(
                    localized: "auth.login.wechat",
                    defaultValue: "微信登录",
                    comment: "WeChat sign in"
                ),
                systemImage: "message.fill",
                prominence: .primary,
                brandTint: AuthBrandColor.weChat,
                provider: .wechat,
                hint: String(
                    localized: "auth.login.wechat.hint",
                    defaultValue: "使用微信账号授权登录",
                    comment: "WeChat sign in hint"
                ),
                action: { await viewModel.signInWithWeChatTapped() }
            )

            cnSignInButton(
                title: String(
                    localized: "auth.login.phoneOtp",
                    defaultValue: "手机号验证码登录",
                    comment: "Phone OTP sign in"
                ),
                systemImage: "message.fill",
                provider: .phoneOtp,
                hint: String(
                    localized: "auth.login.phoneOtp.hint",
                    defaultValue: "输入手机号码并验证验证码完成登录/注册",
                    comment: "Phone OTP hint"
                ),
                action: { isPresentingPhoneOTP = true }
            )

            cnSignInButton(
                title: String(
                    localized: "auth.login.alipay",
                    defaultValue: "支付宝登录",
                    comment: "Alipay sign in"
                ),
                systemImage: "creditcard.fill",
                brandTint: AuthBrandColor.alipay,
                provider: .alipay,
                hint: String(
                    localized: "auth.login.alipay.hint",
                    defaultValue: "使用支付宝账号授权登录",
                    comment: "Alipay sign in hint"
                ),
                action: { await viewModel.signInWithAlipayTapped() }
            )
        }
    }

    private func cnSignInButton(
        title: String,
        systemImage: String,
        prominence: SparkSignInButton.Prominence = .secondary,
        brandTint: Color? = nil,
        provider: SignInProvider,
        hint: String,
        action: @escaping () async -> Void
    ) -> some View {
        SparkSignInButton(
            title: title,
            systemImage: systemImage,
            prominence: prominence,
            brandTint: brandTint,
            isLoading: viewModel.isLoading(for: provider),
            isDisabled: viewModel.isSignInInProgress,
            accessibilityHint: hint,
            action: { Task { await action() } }
        )
    }

    private var orDivider: some View {
        HStack(spacing: 12) {
            Divider()
            Text(String(localized: "auth.login.or", defaultValue: "或", comment: "Divider"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Divider()
        }
        .accessibilityLabel(
            String(localized: "auth.login.or.a11y", defaultValue: "或使用", comment: "Or divider a11y")
        )
    }

    private var appleButton: some View {
        ZStack {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                Task { await viewModel.handleAppleSignInResult(result) }
            }
            .signInWithAppleButtonStyle(appleSignInButtonStyle)
            .frame(maxWidth: .infinity)
            .frame(minHeight: SparkAuthLayout.signInButtonMinHeight)
            .clipShape(RoundedRectangle(cornerRadius: SparkAuthLayout.signInButtonCornerRadius))
            .opacity(viewModel.isLoading(for: .apple) ? 0.65 : 1)
            .allowsHitTesting(!viewModel.isSignInInProgress)

            if viewModel.isLoading(for: .apple) {
                ProgressView()
                    .controlSize(.regular)
            }
        }
        .accessibilityLabel(
            String(localized: "auth.login.apple", defaultValue: "通过 Apple 登录", comment: "Apple sign in")
        )
        .accessibilityAddTraits(viewModel.isLoading(for: .apple) ? [.isButton, .updatesFrequently] : .isButton)
    }

    private var appleSignInButtonStyle: SignInWithAppleButton.Style {
        colorScheme == .dark ? .white : .black
    }
}

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

#Preview("iPad regular") {
    SparkPreviewSupport.iPadRegular {
        LoginView(viewModel: AuthPreviewSupport.makeViewModel())
    }
}
