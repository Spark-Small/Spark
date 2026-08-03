//
//  LaunchTheme.swift
//  坐标系
//
//  Launch / login surfaces and shared controls.
//

import SwiftUI

enum LaunchSurface {
    /// 加载与登录共用舞台底色。
    static let stage = Color(.systemGroupedBackground)
    /// 邀请函纸面：系统灰，避免纯白卡片感。
    static let invitationPaper = Color(.systemGray6)
    /// 信封品牌红。
    static let envelope = Color(red: 0.98, green: 0.10, blue: 0.16)
    static let envelopeLift = Color(red: 1.00, green: 0.28, blue: 0.31)
    static let envelopeDeep = Color(red: 0.96, green: 0.07, blue: 0.13)
}

enum LaunchGeometry {
    static let invitationSurface = "invitationSurface"
}

// MARK: - Buttons

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .contentTransition(.interpolate)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .disabled(!isEnabled)
    }
}

struct WeChatLoginButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "message.fill")
                Text("微信登录")
            }
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
    }
}

struct SecondaryButton: View {
    let title: String
    var systemImage: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
            }
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .buttonBorderShape(.capsule)
    }
}

struct QuietTextButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .buttonStyle(.plain)
    }
}

// MARK: - Motion helpers

struct FloatingAnimationModifier: ViewModifier {
    var enabled: Bool
    var amplitude: CGFloat = LaunchMotion.floatAmplitude
    var cycle: TimeInterval = LaunchMotion.floatCycle

    func body(content: Content) -> some View {
        content
            .phaseAnimator([false, true], trigger: enabled) { view, raised in
                view.offset(y: enabled && raised ? -amplitude : 0)
            } animation: { _ in
                .easeInOut(duration: cycle)
            }
    }
}

extension View {
    func floatingAnimation(
        enabled: Bool,
        amplitude: CGFloat = LaunchMotion.floatAmplitude,
        cycle: TimeInterval = LaunchMotion.floatCycle
    ) -> some View {
        modifier(FloatingAnimationModifier(enabled: enabled, amplitude: amplitude, cycle: cycle))
    }
}
