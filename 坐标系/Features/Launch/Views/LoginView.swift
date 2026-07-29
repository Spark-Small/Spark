//
//  LoginView.swift
//  坐标系
//

import SwiftUI

struct LoginView: View {
    @Bindable var session: LocalAuthSession
    var namespace: Namespace.ID

    @State private var mode: Mode = .choices
    @State private var phone = ""
    @State private var code = ""
    @State private var errorMessage: String?
    @State private var revealStep = 0
    @FocusState private var focusedField: Field?

    private enum Mode { case choices, phone }
    private enum Field { case phone, code }

    private enum Reveal {
        static let logo = 1
        static let title = 2
        static let subtitle = 3
        static let wechat = 4
        static let apple = 5
        static let phone = 6
        static let guest = 7
        static let footer = 8
        static let last = footer
    }

    var body: some View {
        GeometryReader { proxy in
            let inset: CGFloat = 12

            PaperBackground(cornerRadius: 32)
                .matchedGeometryEffect(id: LaunchGeometry.invitationSurface, in: namespace)
                .padding(inset)
                .overlay {
                    ScrollView {
                        VStack(spacing: 0) {
                            Spacer(minLength: proxy.size.height * 0.11)

                            header

                            Group {
                                switch mode {
                                case .choices: choiceControls
                                case .phone: phoneControls
                                }
                            }
                            .padding(.top, 40)

                            Spacer(minLength: 36)

                            chrome(legalFooter, step: Reveal.footer)
                                .padding(.bottom, max(proxy.safeAreaInsets.bottom, 20) + 8)
                        }
                        .frame(minHeight: proxy.size.height - inset * 2)
                        .padding(.horizontal, 36)
                        .animation(LaunchMotion.chromeFade, value: revealStep)
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                }
        }
        .background(InvitationPaper.stage.ignoresSafeArea())
        .task { await runStaggeredReveal() }
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        VStack(spacing: 0) {
            chrome(BrandLogo(size: 48), step: Reveal.logo)
                .padding(.bottom, 28)

            chrome(
                Text("找到值得奔赴的活动，遇见值得相逢的人")
                    .font(.system(.title, design: .serif).weight(.semibold))
                    .foregroundStyle(InvitationPaper.ink)
                    .multilineTextAlignment(.center),
                step: Reveal.title
            )

            chrome(
                Text("你只管出发，同频的人都在路上")
                    .font(.body)
                    .foregroundStyle(InvitationPaper.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 12)
                    .padding(.horizontal, 8),
                step: Reveal.subtitle
            )
        }
    }

    private var choiceControls: some View {
        VStack(spacing: 12) {
            chrome(
                WeChatLoginButton {
                    session.signInDemoWeChat()
                },
                step: Reveal.wechat,
                offset: 8
            )

            chrome(
                SecondaryButton(title: "使用 Apple 登录", systemImage: "apple.logo") {
                    session.signInDemoApple()
                },
                step: Reveal.apple,
                offset: 8
            )

            chrome(
                SecondaryButton(title: "手机号登录") {
                    withAnimation(LaunchMotion.chromeFade) { mode = .phone }
                    focusedField = .phone
                },
                step: Reveal.phone,
                offset: 8
            )

            chrome(
                QuietTextButton(title: "以访客身份继续") {
                    _ = session.signIn(phone: "13800000000", code: LocalAuthSession.demoCode)
                }
                .padding(.top, 6),
                step: Reveal.guest,
                offset: 6
            )
        }
    }

    private var phoneControls: some View {
        VStack(spacing: 16) {
            PaperField(title: "手机号") {
                TextField("", text: $phone, prompt: Text("手机号码").foregroundStyle(.tertiary))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .focused($focusedField, equals: .phone)
            }

            PaperField(title: "验证码") {
                SecureField("", text: $code, prompt: Text("六位验证码").foregroundStyle(.tertiary))
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: .code)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(InvitationPaper.accent.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            PrimaryButton(
                title: "继续",
                isEnabled: phone.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 && !code.isEmpty
            ) {
                submitPhone()
            }

            QuietTextButton(title: "其他登录方式") {
                focusedField = nil
                withAnimation(LaunchMotion.chromeFade) {
                    mode = .choices
                    errorMessage = nil
                }
            }
            .padding(.top, 2)
        }
        .opacity(revealStep >= Reveal.wechat ? 1 : 0)
    }

    private var legalFooter: some View {
        Text("继续即表示你同意《用户协议》与《隐私政策》")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .accessibilityLabel("继续即表示你同意用户协议与隐私政策")
    }

    private func chrome<Content: View>(
        _ content: Content,
        step: Int,
        offset: CGFloat = 6
    ) -> some View {
        content
            .opacity(revealStep >= step ? 1 : 0)
            .offset(y: revealStep >= step ? 0 : offset)
    }

    @MainActor
    private func runStaggeredReveal() async {
        revealStep = 0
        for step in 1...Reveal.last {
            try? await Task.sleep(for: LaunchMotion.chromeStagger)
            revealStep = step
        }
    }

    private func submitPhone() {
        if session.signIn(phone: phone, code: code) {
            errorMessage = nil
        } else {
            errorMessage = "手机号或验证码不正确"
        }
    }
}

#Preview {
    @Previewable @Namespace var ns
    LoginView(session: LocalAuthSession(), namespace: ns)
}
