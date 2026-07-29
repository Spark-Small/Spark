//
//  LaunchTheme.swift
//  坐标系
//
//  Palette, logo, paper surfaces, and launch controls.
//

import SwiftUI

// MARK: - Theme

enum InvitationPaper {
    /// Ivory stage behind the invitation (RGB 255,255,240).
    static let stage = Color("InvitationPageDeep")
    /// Paper surface — soft ivory sheet.
    static let page = Color("InvitationPage")
    /// Primary ink (#1D1D1F) — adaptive text on paper.
    static let ink = Color("InvitationInk")
    /// Solid CTA fill — always dark so borderedProminent keeps white labels in Dark Mode.
    static let solidInk = Color(red: 0.114, green: 0.122, blue: 0.122)
    /// Cinnabar red — brand mark only (RGB 192,30,37).
    static let accent = Color("InvitationAccent")
    /// Deeper cinnabar for gradients.
    static let accentDeep = Color(red: 140 / 255, green: 18 / 255, blue: 24 / 255)
    /// Brighter edge highlight for gradients.
    static let accentLift = Color(red: 220 / 255, green: 58 / 255, blue: 62 / 255)
    static let secondary = Color(red: 0.43, green: 0.43, blue: 0.45)
    static let hairline = Color.primary.opacity(0.06)
}

enum LaunchGeometry {
    static let invitationSurface = "invitationSurface"
    static let envelopeBody = "envelopeBody"
}

// MARK: - Logo

/// Brand lockup: coordinate-origin seal in cinnabar on ivory.
struct BrandLogo: View {
    var size: CGFloat = 72

    var body: some View {
        CoordinateOriginMark(size: size)
            .frame(width: size, height: size)
            .accessibilityLabel("坐标系")
    }
}

/// Literal “坐标系”: axes meet at an origin, framed as a soft invitation seal.
struct CoordinateOriginMark: View {
    var size: CGFloat = 72

    var body: some View {
        let u = size / 72
        ZStack {
            // Soft ivory bloom behind the seal
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            InvitationPaper.page.opacity(0.0),
                            InvitationPaper.accent.opacity(0.08),
                            InvitationPaper.accent.opacity(0.0)
                        ],
                        center: .center,
                        startRadius: 6 * u,
                        endRadius: 40 * u
                    )
                )
                .frame(width: 78 * u, height: 78 * u)

            // Outer seal ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            InvitationPaper.accentDeep.opacity(0.55),
                            InvitationPaper.accentLift.opacity(0.9),
                            InvitationPaper.accent.opacity(0.75),
                            InvitationPaper.accentDeep.opacity(0.55)
                        ],
                        center: .center
                    ),
                    lineWidth: 1.6 * u
                )
                .frame(width: 58 * u, height: 58 * u)

            // Inner thin ring
            Circle()
                .strokeBorder(InvitationPaper.accent.opacity(0.28), lineWidth: 0.7 * u)
                .frame(width: 46 * u, height: 46 * u)

            // Vertical axis
            Capsule(style: .continuous)
                .fill(axisGradient(vertical: true))
                .frame(width: 3.2 * u, height: 34 * u)

            // Horizontal axis
            Capsule(style: .continuous)
                .fill(axisGradient(vertical: false))
                .frame(width: 34 * u, height: 3.2 * u)

            // Origin node
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            InvitationPaper.accentLift,
                            InvitationPaper.accent,
                            InvitationPaper.accentDeep
                        ],
                        center: UnitPoint(x: 0.35, y: 0.32),
                        startRadius: 0,
                        endRadius: 9 * u
                    )
                )
                .frame(width: 14 * u, height: 14 * u)
                .shadow(color: InvitationPaper.accent.opacity(0.28), radius: 3 * u, y: 1 * u)

            // Survey pinpoint
            Circle()
                .fill(InvitationPaper.page)
                .frame(width: 4.2 * u, height: 4.2 * u)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func axisGradient(vertical: Bool) -> LinearGradient {
        LinearGradient(
            colors: [
                InvitationPaper.accentDeep.opacity(0.35),
                InvitationPaper.accent,
                InvitationPaper.accentLift,
                InvitationPaper.accent,
                InvitationPaper.accentDeep.opacity(0.35)
            ],
            startPoint: vertical ? .top : .leading,
            endPoint: vertical ? .bottom : .trailing
        )
    }
}

// MARK: - Surfaces

struct PaperBackground: View {
    var cornerRadius: CGFloat = 28
    var elevated = true

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.55),
                        InvitationPaper.page,
                        InvitationPaper.page.opacity(0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                // Soft edge catch-light
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.55),
                                Color.white.opacity(0.08),
                                Color.black.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            }
            .overlay {
                // Cotton grain — almost invisible
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.015),
                                Color.clear
                            ],
                            center: .topLeading,
                            startRadius: 4,
                            endRadius: 220
                        )
                    )
                    .blendMode(.multiply)
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(elevated ? 0.035 : 0.02), radius: elevated ? 8 : 4, y: elevated ? 3 : 1)
            .shadow(color: .black.opacity(elevated ? 0.055 : 0.03), radius: elevated ? 32 : 16, y: elevated ? 18 : 8)
            .shadow(color: .black.opacity(elevated ? 0.04 : 0.02), radius: elevated ? 64 : 28, y: elevated ? 36 : 14)
    }
}

// MARK: - Buttons

enum WeChatBrand {
    static let green = Color(red: 7 / 255, green: 193 / 255, blue: 96 / 255)
}

/// Compact speech-bubble mark approximating the WeChat logo.
struct WeChatMark: View {
    var size: CGFloat = 18

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height

            var back = Path()
            back.addEllipse(in: CGRect(x: w * 0.08, y: h * 0.05, width: w * 0.62, height: h * 0.55))
            back.move(to: CGPoint(x: w * 0.22, y: h * 0.52))
            back.addLine(to: CGPoint(x: w * 0.12, y: h * 0.72))
            back.addLine(to: CGPoint(x: w * 0.36, y: h * 0.58))
            context.fill(back, with: .color(.white.opacity(0.92)))

            var front = Path()
            front.addEllipse(in: CGRect(x: w * 0.32, y: h * 0.28, width: w * 0.58, height: h * 0.52))
            front.move(to: CGPoint(x: w * 0.72, y: h * 0.72))
            front.addLine(to: CGPoint(x: w * 0.88, y: h * 0.92))
            front.addLine(to: CGPoint(x: w * 0.58, y: h * 0.78))
            context.fill(front, with: .color(.white))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = InvitationPaper.ink
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
        .tint(tint)
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
                WeChatMark(size: 18)
                Text("微信登录")
            }
            .font(.body)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
        }
        .buttonStyle(.borderedProminent)
        .tint(WeChatBrand.green)
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
        .tint(InvitationPaper.ink)
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
            .foregroundStyle(InvitationPaper.secondary)
            .buttonStyle(.plain)
    }
}

struct PaperField<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(InvitationPaper.secondary)
            content
                .font(.body)
                .foregroundStyle(InvitationPaper.ink)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(InvitationPaper.stage.opacity(0.55))
                )
        }
    }
}

// MARK: - Motion

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
