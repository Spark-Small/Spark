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
    /// 信封品牌红（与 AppIcon.icon 渐变一致，Display P3）。
    static let envelope = Color(.displayP3, red: 0.914, green: 0.276, blue: 0.338)
    static let envelopeLift = Color(.displayP3, red: 0.917, green: 0.352, blue: 0.448)
    static let envelopeDeep = Color(.displayP3, red: 0.910, green: 0.199, blue: 0.228)

    /// 启动舞台氛围网格（低饱和系统色，非品牌红面）。
    static var stageMesh: MeshGradient {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                SIMD2(0.0, 0.0), SIMD2(0.5, 0.0), SIMD2(1.0, 0.0),
                SIMD2(0.0, 0.5), SIMD2(0.5, 0.5), SIMD2(1.0, 0.5),
                SIMD2(0.0, 1.0), SIMD2(0.5, 1.0), SIMD2(1.0, 1.0)
            ],
            colors: [
                Color(.systemGray6), Color(.systemBackground), Color(.systemGray5),
                Color(.secondarySystemBackground), Color(.systemGray6), Color(.systemBackground),
                Color(.systemGray5), Color(.secondarySystemGroupedBackground), Color(.systemGray6)
            ]
        )
    }
}

/// 启动舞台：Reduce Motion 时回退纯色，否则 MeshGradient。
struct LaunchStageBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                LaunchSurface.stage
            } else {
                LaunchSurface.stageMesh
            }
        }
        .ignoresSafeArea()
    }
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
