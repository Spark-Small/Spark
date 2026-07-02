// Module: SparkDesignSystem — HIG-aligned full-width sign-in control.

import SwiftUI

/// Full-width sign-in button: system styles, 52pt min height, Dynamic Type, optional brand tint.
public struct SparkSignInButton: View {
    public enum Prominence: Sendable {
        case primary
        case secondary
    }

    private let title: String
    private let systemImage: String
    private let prominence: Prominence
    private let brandTint: Color?
    private let isLoading: Bool
    private let isDisabled: Bool
    private let accessibilityHint: String
    private let action: () -> Void

    public init(
        title: String,
        systemImage: String,
        prominence: Prominence = .secondary,
        brandTint: Color? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        accessibilityHint: String,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.prominence = prominence
        self.brandTint = brandTint
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        Group {
            if prominence == .primary {
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button(action: action) {
                    buttonContent
                }
                .buttonStyle(.bordered)
            }
        }
        .controlSize(.large)
        .tint(resolvedTint)
        .clipShape(RoundedRectangle(cornerRadius: SparkAuthLayout.signInButtonCornerRadius))
        .disabled(isDisabled || isLoading)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isLoading ? [.isButton, .updatesFrequently] : .isButton)
    }

    private var buttonContent: some View {
        ZStack {
            content
                .opacity(isLoading ? 0.25 : 1)
            if isLoading {
                ProgressView()
                    .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: SparkAuthLayout.signInButtonMinHeight)
    }

    private var content: some View {
        HStack(spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.body.weight(.semibold))
                .labelStyle(.titleAndIcon)
        }
    }

    private var resolvedTint: Color? {
        if let brandTint { return brandTint }
        return prominence == .primary ? Color.accentColor : nil
    }
}

#Preview("Sign-in buttons") {
    VStack(spacing: SparkAuthLayout.signInButtonSpacing) {
        SparkSignInButton(
            title: "微信登录",
            systemImage: "message.fill",
            prominence: .primary,
            brandTint: Color(red: 0.03, green: 0.76, blue: 0.38),
            accessibilityHint: "使用微信账号授权登录"
        ) {}
        SparkSignInButton(
            title: "手机号验证码登录",
            systemImage: "iphone",
            isLoading: true,
            accessibilityHint: "输入手机号码并验证验证码完成登录"
        ) {}
        SparkSignInButton(
            title: "支付宝登录",
            systemImage: "creditcard.fill",
            brandTint: Color(red: 0.09, green: 0.47, blue: 0.95),
            accessibilityHint: "使用支付宝账号授权登录"
        ) {}
    }
    .padding(SparkAuthLayout.screenHorizontalPadding)
}
