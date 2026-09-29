//
//  LoginView.swift
//  坐标系
//
//  视频背景 + 系统 Form：字号 / 行高 / 箭头缩放交给 Form 环境；验证码发送后插入。
//

import CoordinateFeatureFlags
import SwiftUI
import UIKit

struct LoginView: View {
    @Bindable var session: LocalAuthSession

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focusedField: Field?

    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var isSendingCode = false
    @State private var isSubmitting = false
    @State private var codeCooldownSeconds = 0
    @State private var hasRequestedCode = false
    @State private var phoneUsedForCode: String?
    @State private var hasAgreedToLegal = false
    @State private var showLegalAlert = false
    @State private var pendingAction: PendingAction?
    @State private var socialUnavailableMessage: String?
    @State private var cooldownTask: Task<Void, Never>?
    @State private var workTask: Task<Void, Never>?
    @State private var workGeneration = 0
    @State private var sendSuccessPulse = 0
    @State private var errorPulse = 0
    @State private var showsControls = false

    private enum Field { case phone, code }

    private enum PendingAction {
        case sendCode, submitPhone, appleLogin, weChatLogin
    }

    private enum BusyFlag {
        case sendingCode, submitting
    }

    private enum Copy {
        static let phone = "手机号"
        static let code = "验证码"
        static let login = "登录"
        static let sendCode = "获取验证码"
        static let apple = "通过 Apple 登录"
        static let wechat = "微信登录"
        static let needPhone = "请输入 11 位手机号"
        static let needCode = "请输入 \(LoginChrome.codeLength) 位验证码"
        static let needSendCode = "请先获取验证码"
        static let wechatUnavailable = "微信登录即将开放，请使用 Apple 或手机号登录。"
        static let codeFooter = "验证码将发送到你的手机。"
        static let codeSent = "验证码已发送"
        static let badCredentials = "手机号或验证码不正确"
        static let needRemoteSMS = "请使用短信验证码登录。"
        static let socialAlertTitle = "暂不可用"
        static let socialAlertDismiss = "好的"
    }

    private var usesRemoteSMS: Bool { FeatureFlags.useRemoteAuth }
    private var phoneNumber: String { LoginChrome.sanitizedPhone(phone) }
    private var isBusy: Bool { isSendingCode || isSubmitting }
    private var canSendCode: Bool {
        LoginChrome.isValidPhone(phone) && !isBusy && codeCooldownSeconds == 0
    }

    private var sendCodeTitle: String {
        codeCooldownSeconds > 0 ? "\(codeCooldownSeconds)s 后可重发" : Copy.sendCode
    }

    private var socialUnavailablePresented: Binding<Bool> {
        Binding(
            get: { socialUnavailableMessage != nil },
            set: { if !$0 { socialUnavailableMessage = nil } }
        )
    }

    var body: some View {
        ZStack {
            LoginBackgroundChrome(isActive: scenePhase == .active)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                Form {
                    credentialsSection
                    actionsSection
                    socialSection
                }
                .formStyle(.grouped)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
                .listSectionSpacing(PlatformMetrics.sectionSpacing)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(showsControls ? 1 : 0)
                .offset(y: showsControls ? 0 : PlatformMetrics.sectionSpacing)
                .allowsHitTesting(showsControls)
                .accessibilityHidden(!showsControls)
            }
        }
        .legalConsentAlert(
            isPresented: $showLegalAlert,
            onAgree: {
                hasAgreedToLegal = true
                guard let action = pendingAction else { return }
                pendingAction = nil
                perform(action)
            },
            onReject: { pendingAction = nil }
        )
        .alert(Copy.socialAlertTitle, isPresented: socialUnavailablePresented) {
            Button(Copy.socialAlertDismiss, role: .cancel) {
                socialUnavailableMessage = nil
            }
        } message: {
            Text(socialUnavailableMessage ?? "")
        }
        .sensoryFeedback(.success, trigger: sendSuccessPulse)
        .sensoryFeedback(.error, trigger: errorPulse)
        .onChange(of: phone) { _, value in applySanitizedPhone(value) }
        .onChange(of: code) { _, value in applySanitizedCode(value) }
        .onAppear(perform: revealControlsIfNeeded)
        .onDisappear {
            cooldownTask?.cancel()
            workTask?.cancel()
        }
    }

    // MARK: - Form sections

    private var credentialsSection: some View {
        Section {
            HStack {
                TextField(Copy.phone, text: $phone)
                    .keyboardType(.numberPad)
                    .textContentType(.telephoneNumber)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .phone)
                    .disabled(isSubmitting)

                LoginSendCodeButton(
                    isLoading: isSendingCode,
                    isEnabled: canSendCode && !isSubmitting,
                    accessibilityTitle: sendCodeTitle,
                    action: { requireLegalConsent(.sendCode) }
                )
            }
            .loginFormMaterialRow()

            if hasRequestedCode {
                TextField(Copy.code, text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
                    .disabled(isSubmitting)
                    .loginFormMaterialRow()
            }

            LegalConsentCheckbox(
                isChecked: $hasAgreedToLegal,
                showAlert: $showLegalAlert,
                centersContent: false
            )
            .disabled(isBusy)
            .loginFormMaterialRow()
        } footer: {
            credentialsFooter
        }
        .animation(.default, value: hasRequestedCode)
    }

    private var actionsSection: some View {
        Section {
            LoginPrimaryButton(
                title: Copy.login,
                isLoading: isSubmitting,
                disabled: isBusy && !isSubmitting,
                action: handleLoginTap
            )
            .loginClearListRow()
        }
    }

    private var socialSection: some View {
        Section {
            HStack(spacing: PlatformMetrics.inlineControlSpacing) {
                Spacer(minLength: 0)
                LoginCircleButton(
                    systemImage: "apple.logo",
                    title: Copy.apple,
                    hint: "使用 Apple 账号登录",
                    disabled: isBusy,
                    action: { requireLegalConsent(.appleLogin) }
                )
                LoginCircleButton(
                    systemImage: "message.fill",
                    title: Copy.wechat,
                    hint: "使用微信账号登录",
                    tint: LoginChrome.wechatGreen,
                    disabled: isBusy,
                    action: { requireLegalConsent(.weChatLogin) }
                )
                Spacer(minLength: 0)
            }
            .loginClearListRow()
        }
    }

    @ViewBuilder
    private var credentialsFooter: some View {
        if let errorMessage {
            Text(errorMessage)
                .foregroundStyle(PlatformStatus.danger)
                .accessibilityAddTraits(.updatesFrequently)
        } else if !hasRequestedCode {
            Text(Copy.codeFooter)
        }
    }

    private func revealControlsIfNeeded() {
        guard !showsControls else { return }
        if reduceMotion {
            showsControls = true
        } else {
            PlatformMotion.withAnimation(.easeOut(duration: 0.45)) {
                showsControls = true
            }
        }
    }

    // MARK: - Actions

    private func handleLoginTap() {
        guard LoginChrome.isValidPhone(phone) else {
            presentError(Copy.needPhone, focus: .phone)
            return
        }
        guard hasRequestedCode else {
            presentError(Copy.needSendCode, focus: .phone)
            return
        }
        guard LoginChrome.isValidCode(code) else {
            presentError(Copy.needCode, focus: .code)
            return
        }
        focusedField = nil
        requireLegalConsent(.submitPhone)
    }

    private func requireLegalConsent(_ action: PendingAction) {
        guard hasAgreedToLegal else {
            pendingAction = action
            showLegalAlert = true
            return
        }
        perform(action)
    }

    private func perform(_ action: PendingAction) {
        switch action {
        case .sendCode: sendCode()
        case .submitPhone: submitPhone()
        case .appleLogin: signInWithApple()
        case .weChatLogin: signInWithWeChat()
        }
    }

    private func sendCode() {
        guard LoginChrome.isValidPhone(phone) else {
            presentError(Copy.needPhone, focus: .phone)
            return
        }

        if usesRemoteSMS {
            let generation = beginWork()
            isSendingCode = true
            errorMessage = nil
            workTask = Task { @MainActor in
                defer { finishWork(generation, clearing: .sendingCode) }
                if let err = await session.sendRemoteSMSCode(phone: phoneNumber) {
                    presentError(err, focus: .phone)
                    return
                }
                guard !Task.isCancelled, generation == workGeneration else { return }
                revealCodeFieldAfterSend()
            }
            return
        }

        #if DEBUG
        errorMessage = nil
        revealCodeFieldAfterSend()
        #else
        presentError(Copy.needRemoteSMS, focus: .phone)
        #endif
    }

    private func revealCodeFieldAfterSend() {
        hasRequestedCode = true
        phoneUsedForCode = phoneNumber
        startCooldown()
        focusedField = .code
        sendSuccessPulse += 1
        announce(Copy.codeSent)
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

    private func submitPhone() {
        errorMessage = nil
        if usesRemoteSMS {
            let generation = beginWork()
            isSubmitting = true
            workTask = Task { @MainActor in
                defer { finishWork(generation, clearing: .submitting) }
                if let err = await session.signInRemote(phone: phoneNumber, code: code) {
                    presentError(err, focus: .code)
                }
            }
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }
        #if DEBUG
        if !session.signIn(phone: phoneNumber, code: code) {
            presentError(Copy.badCredentials, focus: .code)
        }
        #else
        presentError(Copy.needRemoteSMS, focus: .code)
        #endif
    }

    private func signInWithApple() {
        let generation = beginWork()
        workTask = Task { @MainActor in
            if let err = await session.signInWithApple() {
                guard generation == workGeneration else { return }
                socialUnavailableMessage = err
            }
        }
    }

    private func signInWithWeChat() {
        #if DEBUG
        session.signInDemoWeChat()
        #else
        socialUnavailableMessage = Copy.wechatUnavailable
        #endif
    }

    private func beginWork() -> Int {
        workTask?.cancel()
        workGeneration += 1
        isSendingCode = false
        isSubmitting = false
        return workGeneration
    }

    private func finishWork(_ generation: Int, clearing flag: BusyFlag) {
        guard generation == workGeneration else { return }
        switch flag {
        case .sendingCode: isSendingCode = false
        case .submitting: isSubmitting = false
        }
    }

    private func applySanitizedPhone(_ value: String) {
        let sanitized = LoginChrome.sanitizedPhone(value)
        if sanitized != value { phone = sanitized }
        clearErrorIfMatches(Copy.needPhone)
        clearErrorIfMatches(Copy.needSendCode)
        guard let sentTo = phoneUsedForCode, sanitized != sentTo else { return }
        resetCodeRequest()
    }

    private func applySanitizedCode(_ value: String) {
        let sanitized = LoginChrome.sanitizedCode(value)
        if sanitized != value { code = sanitized }
        clearErrorIfMatches(Copy.needCode)
    }

    private func resetCodeRequest() {
        cooldownTask?.cancel()
        codeCooldownSeconds = 0
        code = ""
        phoneUsedForCode = nil
        hasRequestedCode = false
        clearErrorIfMatches(Copy.needCode)
    }

    private func presentError(_ message: String, focus: Field) {
        errorMessage = message
        focusedField = focus
        errorPulse += 1
        announce(message)
    }

    private func clearErrorIfMatches(_ message: String) {
        if errorMessage == message { errorMessage = nil }
    }

    private func announce(_ message: String) {
        guard !message.isEmpty else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

#Preview {
    LoginView(session: LocalAuthSession())
}
