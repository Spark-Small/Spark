//
//  LoginChrome.swift
//  坐标系
//
//  登录 UI 共用：校验、文案、控件、手机号验证码草稿。
//

import Observation
import SwiftUI

enum LoginChrome {
    static let codeLength = AuthCredentialFormat.codeLength
    static let phoneLength = AuthCredentialFormat.phoneLength
    static let smsCooldownSeconds = AuthCredentialFormat.smsCooldownSeconds
    static let wechatGreen = Color(.displayP3, red: 0.027, green: 0.757, blue: 0.376)

    static func sanitizedPhone(_ raw: String) -> String {
        AuthCredentialFormat.sanitizedPhone(raw)
    }

    static func sanitizedCode(_ raw: String) -> String {
        AuthCredentialFormat.sanitizedCode(raw)
    }

    static func isValidPhone(_ raw: String) -> Bool {
        AuthCredentialFormat.isValidPhone(raw)
    }

    static func isValidCode(_ raw: String) -> Bool {
        AuthCredentialFormat.isValidCode(raw)
    }
}

enum LoginAuthCopy {
    static let phone = "手机号"
    static let code = "验证码"
    static let login = "登录"
    static let sendCode = "获取验证码"
    static let sendingCode = "正在发送验证码"
    static let apple = "通过 Apple 登录"
    static let wechat = "微信登录"
    static let appleCreate = "使用 Apple 创建"
    static let wechatCreate = "使用微信创建"
    static let needPhone = "请输入 11 位手机号"
    static let needCode = "请输入 \(LoginChrome.codeLength) 位验证码"
    static let needSendCode = "请先获取验证码"
    static let codeSent = "验证码已发送，请查收短信。"
    static let badCredentials = "手机号或验证码不正确"
    static let needRemoteSMS = "请使用短信验证码登录。"
    static let needRemoteSMSCreate = "请使用短信验证码创建账号。"
    static let demoCredentialsHint = "请输入有效手机号，并使用演示验证码。"
    static let socialAlertTitle = "暂不可用"
    static let socialAlertDismiss = "好的"
    static let dismissKeyboard = "完成"
    static let cancel = "取消"
    static let createAccount = "创建账号"
    static let createLegalFooter = "创建账号前需同意用户协议与隐私政策。"
    static let otherMethods = "其他方式"
    static let otherMethodsFooter = "推荐使用 Apple 或手机号短信验证码创建账号。"
    static let otherMethodsFooterWeChatPending = "推荐使用 Apple 或手机号短信验证码创建账号。微信需完成 OpenSDK 接入后可用。"
    static let appleHint = "使用 Apple 账号登录"
    static let wechatHint = "使用微信账号登录"
    static let appleCreateHint = "使用 Apple 账号创建"
    static let wechatCreateHint = "使用微信账号创建"
}

/// 登录 / 创建账号共用的手机号 + 验证码输入态。
@MainActor
@Observable
final class LoginPhoneCodeDraft {
    var phone = ""
    var code = ""
    private(set) var codeCooldownSeconds = 0
    private(set) var hasRequestedCode = false

    private var phoneUsedForCode: String?
    private var cooldownTask: Task<Void, Never>?

    var sanitizedPhone: String { LoginChrome.sanitizedPhone(phone) }

    func canSendCode(isBusy: Bool) -> Bool {
        LoginChrome.isValidPhone(phone) && !isBusy && codeCooldownSeconds == 0
    }

    var sendCodeTitle: String {
        codeCooldownSeconds > 0
            ? "\(codeCooldownSeconds)s 后可重发"
            : LoginAuthCopy.sendCode
    }

    func applySanitizedPhone() {
        let sanitized = LoginChrome.sanitizedPhone(phone)
        if sanitized != phone { phone = sanitized }
        guard let sentTo = phoneUsedForCode, sanitized != sentTo else { return }
        resetCodeRequest()
    }

    func applySanitizedCode() {
        let sanitized = LoginChrome.sanitizedCode(code)
        if sanitized != code { code = sanitized }
    }

    func markCodeSent(to sentTo: String) {
        hasRequestedCode = true
        phoneUsedForCode = sentTo
        startCooldown()
    }

    func resetCodeRequest() {
        cooldownTask?.cancel()
        codeCooldownSeconds = 0
        code = ""
        phoneUsedForCode = nil
        hasRequestedCode = false
    }

    func cancel() {
        cooldownTask?.cancel()
    }

    /// 提交前校验；失败返回文案。
    func validateForSubmit() -> String? {
        guard LoginChrome.isValidPhone(phone) else { return LoginAuthCopy.needPhone }
        guard hasRequestedCode else { return LoginAuthCopy.needSendCode }
        guard LoginChrome.isValidCode(code) else { return LoginAuthCopy.needCode }
        return nil
    }

    private func startCooldown() {
        cooldownTask?.cancel()
        codeCooldownSeconds = LoginChrome.smsCooldownSeconds
        cooldownTask = Task { @MainActor in
            while codeCooldownSeconds > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                codeCooldownSeconds -= 1
            }
        }
    }
}

extension View {
    func loginFieldRowPadding() -> some View {
        padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
    }

    /// 系统表单 sheet：仅 `.large`。
    func loginSheetChrome() -> some View {
        presentationDetents([.large])
            .presentationDragIndicator(.visible)
    }

    /// 兼容转发 → `platformCredentialTextInput(.phone)`；新代码请直调 Platform 模块。
    func loginCredentialFieldStyle() -> some View {
        platformCredentialTextInput(.phone)
    }
}

struct LoginMaterialCard<Content: View>: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(spacing: 0) { content() }
            .background {
                if reduceTransparency {
                    PlatformMetrics.cardShape
                        .fill(Color(.secondarySystemGroupedBackground))
                } else {
                    PlatformMetrics.cardShape
                        .fill(.regularMaterial)
                }
            }
            .clipShape(PlatformMetrics.cardShape)
    }
}

struct LoginSendCodeButton: View {
    var title: String
    var loadingTitle = LoginAuthCopy.sendingCode
    var isLoading: Bool
    var isEnabled: Bool
    let action: () -> Void

    @State private var selectionPulse = 0

    var body: some View {
        Button {
            selectionPulse += 1
            action()
        } label: {
            if isLoading {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text(title)
                    .font(.body)
            }
        }
        .buttonStyle(.borderless)
        .disabled(!isEnabled || isLoading)
        .sensoryFeedback(.selection, trigger: selectionPulse)
        .accessibilityLabel(isLoading ? loadingTitle : title)
        .accessibilityHint(isLoading || !isEnabled ? "" : "发送短信验证码")
    }
}

struct LoginPrimaryButton: View {
    let title: String
    var loadingTitle = "登录中…"
    var isLoading = false
    var disabled = false
    let action: () -> Void

    @State private var selectionPulse = 0

    var body: some View {
        Button {
            selectionPulse += 1
            action()
        } label: {
            HStack(spacing: PlatformMetrics.inlineControlSpacing) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(isLoading ? loadingTitle : title)
            }
            .frame(maxWidth: .infinity)
        }
        .activityPrimaryCTA(controlSize: .large)
        .buttonSizing(.flexible)
        .disabled(disabled || isLoading)
        .sensoryFeedback(.selection, trigger: selectionPulse)
        .accessibilityLabel(isLoading ? loadingTitle : title)
    }
}

struct LoginCircleButton: View {
    let systemImage: String
    let title: String
    let hint: String
    var tint: Color = .primary
    var disabled = false
    let action: () -> Void

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements
    @State private var selectionPulse = 0

    var body: some View {
        let side = chromeMeasurements.navigationBarButtonSide
        Button {
            selectionPulse += 1
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(tint)
                .frame(width: side, height: side)
                .contentShape(Circle())
        }
        .platformToolbarCircleStyle()
        .disabled(disabled)
        .sensoryFeedback(.selection, trigger: selectionPulse)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}

/// Apple + 可选微信圆形社交入口。
struct LoginSocialCircleRow: View {
    var isBusy: Bool
    var appleTitle: String
    var appleHint: String
    var wechatTitle: String
    var wechatHint: String
    let onApple: () -> Void
    let onWeChat: () -> Void

    var body: some View {
        HStack(spacing: PlatformMetrics.inlineControlSpacing) {
            Spacer(minLength: 0)
            LoginCircleButton(
                systemImage: "apple.logo",
                title: appleTitle,
                hint: appleHint,
                disabled: isBusy,
                action: onApple
            )
            if WeChatSignInService.isAvailable {
                LoginCircleButton(
                    systemImage: "message.fill",
                    title: wechatTitle,
                    hint: wechatHint,
                    tint: LoginChrome.wechatGreen,
                    disabled: isBusy,
                    action: onWeChat
                )
            }
            Spacer(minLength: 0)
        }
    }
}
