//
//  LoginChrome.swift
//  坐标系
//
//  登录校验、Form 行材质、主 CTA / 社交圆钮。
//

import SwiftUI

enum LoginChrome {
    static let codeLength = 6
    static let phoneLength = 11
    static let smsCooldownSeconds = 60

    static let wechatGreen = Color(.displayP3, red: 0.027, green: 0.757, blue: 0.376)

    static func sanitizedPhone(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(phoneLength))
    }

    static func sanitizedCode(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(codeLength))
    }

    static func isValidPhone(_ raw: String) -> Bool {
        let digits = sanitizedPhone(raw)
        return digits.count == phoneLength && digits.hasPrefix("1")
    }

    static func isValidCode(_ raw: String) -> Bool {
        sanitizedCode(raw).count == codeLength
    }
}

extension View {
    /// 凭证行：系统 Form 行 inset / 行高；背景为 Regular Material。
    func loginFormMaterialRow() -> some View {
        listRowBackground(LoginFormMaterialRowBackground())
    }

    /// CTA / 社交：透明行底，露出视频与玻璃控件。
    func loginClearListRow() -> some View {
        listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

private struct LoginFormMaterialRowBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        if reduceTransparency {
            Color(.secondarySystemGroupedBackground)
        } else {
            Rectangle().fill(.regularMaterial)
        }
    }
}

/// 发送验证码：系统 `arrow.right.circle` + `.title3`（Dynamic Type）。
struct LoginSendCodeButton: View {
    var isLoading: Bool
    var isEnabled: Bool
    var accessibilityTitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .controlSize(.regular)
            } else {
                Image(systemName: "arrow.right.circle")
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isEnabled ? .secondary : .tertiary)
            }
        }
        .buttonStyle(.borderless)
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityTitle)
        .accessibilityHint("发送短信验证码")
    }
}

struct LoginPrimaryButton: View {
    let title: String
    var loadingTitle = "登录中…"
    var isLoading = false
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        .tint(PlatformAction.brandAccent)
        .disabled(disabled || isLoading)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(tint)
        }
        .activityGlassIcon()
        .platformMinHitTarget()
        .disabled(disabled)
        .accessibilityLabel(title)
        .accessibilityHint(hint)
    }
}
