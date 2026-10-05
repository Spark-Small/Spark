//
//  LoginView.swift
//  坐标系
//

import CoordinateFeatureFlags
import SwiftUI
import UIKit

struct LoginView: View {
    @Bindable var session: LocalAuthSession

    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focusedField: Field?

    @State private var isLoginSheetPresented = false
    @State private var draft = LoginPhoneCodeDraft()
    @State private var work = LoginAuthWorkGate()
    @State private var errorMessage: String?
    @State private var hasAgreedToLegal = false
    @State private var showLegalAlert = false
    @State private var pendingAction: PendingAction?
    @State private var socialUnavailableMessage: String?
    @State private var sendSuccessPulse = 0
    @State private var errorPulse = 0

    private enum Field { case phone, code }
    private enum PendingAction { case sendCode, submitPhone, appleLogin, weChatLogin }

    private var usesRemoteSMS: Bool { FeatureFlags.useRemoteAuth }
    private var socialUnavailablePresented: Binding<Bool> {
        Binding(
            get: { socialUnavailableMessage != nil },
            set: { if !$0 { socialUnavailableMessage = nil } }
        )
    }

    var body: some View {
        LoginBackgroundChrome(isActive: scenePhase == .active)
            .safeAreaInset(edge: .bottom) {
                if !isLoginSheetPresented {
                    LoginPrimaryButton(title: LoginAuthCopy.login) {
                        isLoginSheetPresented = true
                    }
                    .padding(.horizontal, PlatformMetrics.contentInset)
                    .padding(.bottom, PlatformMetrics.sectionSpacing)
                }
            }
            .sheet(isPresented: $isLoginSheetPresented) {
                NavigationStack {
                    ScrollView {
                        loginForm
                    }
                    .platformTextInputScrollChrome()
                    .scrollBounceBehavior(.basedOnSize)
                    .navigationTitle(LoginAuthCopy.login)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(LoginAuthCopy.cancel) {
                                focusedField = nil
                                isLoginSheetPresented = false
                            }
                        }
                        ToolbarItemGroup(placement: .keyboard) {
                            Spacer()
                            Button(LoginAuthCopy.dismissKeyboard) { focusedField = nil }
                                .fontWeight(.semibold)
                        }
                    }
                }
                .loginSheetChrome()
                .legalConsentAlert(
                    isPresented: $showLegalAlert,
                    onAgree: {
                        hasAgreedToLegal = true
                        if let method = analyticsMethod(for: pendingAction) {
                            AuthAnalytics.legalAccepted(method: method, source: .login)
                        }
                        guard let action = pendingAction else { return }
                        pendingAction = nil
                        perform(action)
                    },
                    onReject: {
                        if let method = analyticsMethod(for: pendingAction) {
                            AuthAnalytics.legalRejected(method: method, source: .login)
                        }
                        pendingAction = nil
                    }
                )
                .alert(LoginAuthCopy.socialAlertTitle, isPresented: socialUnavailablePresented) {
                    Button(LoginAuthCopy.socialAlertDismiss, role: .cancel) {
                        socialUnavailableMessage = nil
                    }
                } message: {
                    Text(socialUnavailableMessage ?? "")
                }
                .sensoryFeedback(.success, trigger: sendSuccessPulse)
                .sensoryFeedback(.error, trigger: errorPulse)
                .onAppear { AuthAnalytics.sheetPresented(source: .login) }
                .onDisappear { focusedField = nil }
            }
            .onChange(of: draft.phone) { _, _ in
                draft.applySanitizedPhone()
                errorMessage = nil
            }
            .onChange(of: draft.code) { _, _ in
                draft.applySanitizedCode()
                errorMessage = nil
            }
            .onDisappear {
                draft.cancel()
                work.cancel()
            }
    }

    private var loginForm: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            credentialsCard
            statusFooter

            LoginPrimaryButton(
                title: LoginAuthCopy.login,
                isLoading: work.isSubmitting,
                disabled: work.isBusy && !work.isSubmitting,
                action: handleLoginTap
            )

            LoginSocialCircleRow(
                isBusy: work.isBusy,
                appleTitle: LoginAuthCopy.apple,
                appleHint: LoginAuthCopy.appleHint,
                wechatTitle: LoginAuthCopy.wechat,
                wechatHint: LoginAuthCopy.wechatHint,
                onApple: { requireLegalConsent(.appleLogin) },
                onWeChat: { requireLegalConsent(.weChatLogin) }
            )
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.top, PlatformMetrics.sectionHeaderSpacing)
        .padding(.bottom, PlatformMetrics.sectionSpacing)
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var credentialsCard: some View {
        LoginMaterialCard {
            phoneRow

            if draft.hasRequestedCode {
                Divider()
                TextField(LoginAuthCopy.code, text: $draft.code)
                    .platformCredentialTextInput(.oneTimeCode)
                    .focused($focusedField, equals: .code)
                    .disabled(work.isBusy)
                    .loginFieldRowPadding()
            }

            Divider()

            LegalConsentCheckbox(
                isChecked: $hasAgreedToLegal,
                showAlert: $showLegalAlert,
                centersContent: false
            )
            .disabled(work.isBusy)
            .loginFieldRowPadding()
        }
        .animation(.default, value: draft.hasRequestedCode)
    }

    private var phoneRow: some View {
        HStack(spacing: PlatformMetrics.inlineControlSpacing) {
            TextField(LoginAuthCopy.phone, text: $draft.phone)
                .platformCredentialTextInput(.phone)
                .focused($focusedField, equals: .phone)
                .disabled(work.isBusy)

            LoginSendCodeButton(
                title: draft.sendCodeTitle,
                isLoading: work.isSendingCode,
                isEnabled: draft.canSendCode(isBusy: work.isBusy),
                action: { requireLegalConsent(.sendCode) }
            )
        }
        .loginFieldRowPadding()
    }

    @ViewBuilder
    private var statusFooter: some View {
        if let errorMessage {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(PlatformStatus.danger)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.updatesFrequently)
        } else if draft.hasRequestedCode {
            Text(LoginAuthCopy.codeSent)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.updatesFrequently)
        }
    }

    // MARK: - Actions

    private func handleLoginTap() {
        if let message = draft.validateForSubmit() {
            presentError(message, focus: message == LoginAuthCopy.needCode ? .code : .phone)
            return
        }
        focusedField = nil
        requireLegalConsent(.submitPhone)
    }

    private func requireLegalConsent(_ action: PendingAction) {
        if let method = analyticsMethod(for: action) {
            AuthAnalytics.methodTapped(method: method, source: .login)
        }
        focusedField = nil
        guard hasAgreedToLegal else {
            if let method = analyticsMethod(for: action) {
                AuthAnalytics.legalPrompt(method: method, source: .login)
            }
            pendingAction = action
            showLegalAlert = true
            return
        }
        perform(action)
    }

    private func analyticsMethod(for action: PendingAction?) -> AuthAnalytics.Method? {
        switch action {
        case .appleLogin: .apple
        case .weChatLogin: .wechat
        case .sendCode, .submitPhone: .phone
        case .none: nil
        }
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
        guard AuthCredentialFormat.isValidPhone(draft.phone) else {
            presentError(LoginAuthCopy.needPhone, focus: .phone)
            return
        }

        let sentTo = draft.sanitizedPhone
        if usesRemoteSMS {
            errorMessage = nil
            work.run(.sendingCode) { generation in
                if let err = await session.sendRemoteSMSCode(phone: sentTo) {
                    presentError(err, focus: .phone)
                    return
                }
                guard work.isCurrent(generation) else { return }
                revealCodeFieldAfterSend(to: sentTo)
            }
            return
        }

        #if DEBUG
        errorMessage = nil
        revealCodeFieldAfterSend(to: sentTo)
        #else
        presentError(LoginAuthCopy.needRemoteSMS, focus: .phone)
        #endif
    }

    private func revealCodeFieldAfterSend(to sentTo: String) {
        draft.markCodeSent(to: sentTo)
        focusedField = .code
        sendSuccessPulse += 1
        announce(LoginAuthCopy.codeSent)
    }

    private func submitPhone() {
        errorMessage = nil
        if usesRemoteSMS {
            work.run(.submitting) { _ in
                if let err = await session.signInRemote(
                    phone: draft.sanitizedPhone,
                    code: draft.code
                ) {
                    presentError(err, focus: .code)
                }
            }
            return
        }

        #if DEBUG
        if !session.signIn(phone: draft.sanitizedPhone, code: draft.code) {
            presentError(LoginAuthCopy.badCredentials, focus: .code)
        }
        #else
        presentError(LoginAuthCopy.needRemoteSMS, focus: .code)
        #endif
    }

    private func signInWithApple() {
        work.run(.social) { generation in
            if let err = await session.signInWithApple(source: .login) {
                guard work.isCurrent(generation) else { return }
                socialUnavailableMessage = err
            }
        }
    }

    private func signInWithWeChat() {
        work.run(.social) { generation in
            if let err = await session.signInWithWeChat(source: .login) {
                guard work.isCurrent(generation) else { return }
                socialUnavailableMessage = err
            }
        }
    }

    private func presentError(_ message: String, focus: Field) {
        errorMessage = message
        focusedField = focus
        errorPulse += 1
        announce(message)
    }

    private func announce(_ message: String) {
        guard !message.isEmpty else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}

#Preview {
    LoginView(session: LocalAuthSession())
}
