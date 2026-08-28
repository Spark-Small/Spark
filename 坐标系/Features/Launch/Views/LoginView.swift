//
//  LoginView.swift
//  坐标系
//
//  信纸展开后的登录页：天气水彩纸面 + 信封小人问候 + 系统登录控件。
//

import SwiftUI

struct LoginView: View {
    @Bindable var session: LocalAuthSession

    @State private var mode: Mode = .choices
    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var revealStep = 0
    @State private var weather = GreetingWeatherStore.shared
    @State private var hasAgreedToLegal = false
    @State private var showLegalAlert = false
    @State private var pendingLoginAction: (() -> Void)?
    @FocusState private var focusedField: Field?

    private enum Mode { case choices, phone }
    private enum Field { case phone, code }

    /// 页头 → 登录区 → 页脚，三组安静出现。
    private enum Reveal: Int {
        case header = 1
        case controls = 2
        case footer = 3
    }

    var body: some View {
        GeometryReader { proxy in
            TimelineView(.periodic(from: .now, by: 60)) { context in
                let note = InvitationNote.make(date: context.date, weather: weather.reading)

                ScrollView {
                    VStack(spacing: 0) {
                        header(note: note)
                            .padding(.horizontal, 36)

                        Spacer(minLength: 36)

                        Group {
                            if mode == .choices {
                                choiceControls
                                    .padding(.horizontal, 36)
                            } else {
                                phoneControls
                            }
                        }
                        .opacity(revealStep >= Reveal.controls.rawValue ? 1 : 0)

                        Spacer(minLength: 36)

                        chrome(legalFooter, step: .footer)
                            .padding(.horizontal, 36)
                            .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 8)
                    }
                    .padding(.top, max(proxy.safeAreaInsets.top, 20) + 24)
                    .frame(minHeight: proxy.size.height)
                    .animation(LaunchMotion.chromeFade, value: revealStep)
                    .animation(LaunchMotion.chromeFade, value: mode)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .background {
                    paperSurface(note: note)
                }
            }
        }
        .legalConsentAlert(
            isPresented: $showLegalAlert,
            onAgree: {
                hasAgreedToLegal = true
                let action = pendingLoginAction
                pendingLoginAction = nil
                action?()
                Task { await PermissionLaunchPrompts.requestTrackingAfterConsentIfNeeded() }
            },
            onReject: {
                pendingLoginAction = nil
            }
        )
        .task {
            await runStaggeredReveal()
            await LaunchWeather.refreshIfAuthorized(weather)
            if LegalConsentPreference.isAccepted {
                await PermissionLaunchPrompts.requestTrackingAfterConsentIfNeeded()
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// 纸面与天气水彩铺满整屏，含安全区。
    private func paperSurface(note: InvitationNote) -> some View {
        LaunchSurface.invitationPaper
            .overlay {
                InvitationPaperArtwork(
                    systemImage: note.systemImage,
                    presentation: .fullPage
                )
                .opacity(0.88)
            }
            .ignoresSafeArea()
    }

    private func header(note: InvitationNote) -> some View {
        HStack(alignment: .center, spacing: 14) {
            chrome(EnvelopeMascot(), step: .header)

            VStack(alignment: .leading, spacing: 0) {
                chrome(
                    Text(note.greetingTitle)
                        .font(.system(.title2, design: .serif).weight(.medium))
                        .foregroundStyle(.primary.opacity(0.88)),
                    step: .header
                )

                chrome(
                    Text(note.shortMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 8),
                    step: .header
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var choiceControls: some View {
        VStack(spacing: 12) {
            chrome(
                WeChatLoginButton {
                    requireLegalConsent { session.signInDemoWeChat() }
                },
                step: .controls,
                offset: 8
            )
            chrome(
                SecondaryButton(title: "使用 Apple 登录", systemImage: "apple.logo") {
                    requireLegalConsent { session.signInDemoApple() }
                },
                step: .controls,
                offset: 8
            )
            chrome(
                SecondaryButton(title: "手机号登录") {
                    requireLegalConsent {
                        withAnimation(LaunchMotion.chromeFade) { mode = .phone }
                        focusedField = .phone
                    }
                },
                step: .controls,
                offset: 8
            )
            chrome(
                QuietTextButton(title: "以访客身份继续") {
                    requireLegalConsent { session.continueAsGuest() }
                }
                .padding(.top, 6),
                step: .controls,
                offset: 6
            )
        }
    }

    private var phoneControls: some View {
        Form {
            Section {
                TextField("手机号码", text: $phone)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .phone)
                SecureField("验证码", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(PlatformStatus.danger)
                }
            }

            Section {
                Button("继续") {
                    requireLegalConsent(submitPhone)
                }
                .fontWeight(.semibold)
                .disabled(
                    phone.trimmingCharacters(in: .whitespacesAndNewlines).count < 8
                        || code.isEmpty
                )

                Button("其他登录方式") {
                    focusedField = nil
                    withAnimation(LaunchMotion.chromeFade) {
                        mode = .choices
                        errorMessage = nil
                    }
                }
            } footer: {
                Text("本地演示验证码：\(LocalAuthSession.demoCode)")
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .scrollDisabled(true)
        .listSectionSpacing(.compact)
        // 嵌在登录页 ScrollView 内：收起 Form 自身滚动，高度随内容。
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var legalFooter: some View {
        LegalConsentCheckbox(
            isChecked: $hasAgreedToLegal,
            showAlert: $showLegalAlert
        )
    }

    private func requireLegalConsent(_ action: @escaping () -> Void) {
        if hasAgreedToLegal {
            action()
        } else {
            pendingLoginAction = action
            showLegalAlert = true
        }
    }

    private func chrome<Content: View>(
        _ content: Content,
        step: Reveal,
        offset: CGFloat = 6
    ) -> some View {
        content
            .opacity(revealStep >= step.rawValue ? 1 : 0)
            .offset(y: revealStep >= step.rawValue ? 0 : offset)
    }

    @MainActor
    private func runStaggeredReveal() async {
        revealStep = 0
        for step in 1...Reveal.footer.rawValue {
            try? await Task.sleep(for: LaunchMotion.chromeStagger)
            revealStep = step
        }
    }

    private func submitPhone() {
        errorMessage = session.signIn(phone: phone, code: code)
            ? nil
            : "手机号或验证码不正确"
    }
}

#Preview {
    LoginView(session: LocalAuthSession())
}
