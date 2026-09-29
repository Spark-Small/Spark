//
//  PlatformAccessibilityChrome.swift
//  坐标系
//
//  减弱动态效果 / 降低透明度 / 最小点击区域（HIG 无障碍）。
//

import SwiftUI
import UIKit

@MainActor
enum PlatformMotion {
    /// 系统「减弱动态效果」是否开启（非 View 上下文可用）。
    static var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// `accessibilityReduceMotion` 开启时返回 `nil`，关闭系统隐式动画。
    static func resolved(_ animation: Animation?, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }

    /// 尊重减弱动态效果的 `withAnimation`（HIG Accessibility）。
    static func withAnimation<Result>(
        _ animation: Animation? = .default,
        _ body: () throws -> Result
    ) rethrows -> Result {
        if let resolved = resolved(animation, reduceMotion: isReduceMotionEnabled) {
            return try SwiftUI.withAnimation(resolved, body)
        }
        return try body()
    }
}

extension View {
    /// 尊重「减弱动态效果」的 `.animation(_:value:)`。
    func platformAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        modifier(PlatformAnimationModifier(animation: animation, value: value))
    }

    /// 材质背景：降低透明度时退化为不透明系统底色。
    func platformThinMaterialBackground<S: Shape>(in shape: S) -> some View {
        modifier(PlatformThinMaterialBackgroundModifier(shape: shape))
    }

    func platformUltraThinMaterialBackground<S: Shape>(in shape: S) -> some View {
        modifier(PlatformUltraThinMaterialBackgroundModifier(shape: shape))
    }

    func platformBarMaterialBackground<S: Shape>(in shape: S) -> some View {
        modifier(PlatformBarMaterialBackgroundModifier(shape: shape))
    }

    /// 全宽 bar 材质（输入栏 / 底栏）；降低透明度时用不透明分组底。
    func platformBarMaterialFill() -> some View {
        modifier(PlatformBarMaterialFillModifier())
    }

    /// Photos 式圆形 glass：降低透明度时改 `.bordered`。
    func platformToolbarCircleStyle() -> some View {
        modifier(PlatformAccessibleGlassCircleModifier(controlSize: PlatformToolbarChrome.controlSize))
    }

    /// Photos 式胶囊 glass（顶栏 principal）。
    func platformToolbarPrincipalCapsuleStyle() -> some View {
        modifier(PlatformAccessibleGlassCapsuleModifier(controlSize: PlatformToolbarChrome.controlSize))
    }

    /// Composer / 探测用圆形 glass（大号）。
    func platformComposerCircleStyle(prominent: Bool = false) -> some View {
        modifier(
            PlatformAccessibleGlassCircleModifier(
                controlSize: PlatformMessagesChrome.composerControlSize,
                prominent: prominent
            )
        )
    }

    /// 输入框胶囊 glass：降低透明度时用不透明填充。
    func platformComposerFieldChrome() -> some View {
        modifier(PlatformComposerFieldChromeModifier())
    }

    /// 顶栏头像盘外圈：降低透明度时去掉 glassEffect。
    func platformToolbarAvatarRing() -> some View {
        modifier(PlatformToolbarAvatarRingModifier())
    }

    /// 最小可点区域（默认 44pt）。
    func platformMinHitTarget(_ side: CGFloat = 44) -> some View {
        frame(minWidth: side, minHeight: side)
            .contentShape(Rectangle())
    }
}

private struct PlatformAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let animation: Animation?
    let value: V

    func body(content: Content) -> some View {
        content.animation(PlatformMotion.resolved(animation, reduceMotion: reduceMotion), value: value)
    }
}

private struct PlatformThinMaterialBackgroundModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.secondarySystemBackground), in: shape)
        } else {
            content.background(.thinMaterial, in: shape)
        }
    }
}

private struct PlatformUltraThinMaterialBackgroundModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.tertiarySystemBackground), in: shape)
        } else {
            content.background(.ultraThinMaterial, in: shape)
        }
    }
}

private struct PlatformBarMaterialBackgroundModifier<S: Shape>: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let shape: S

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.secondarySystemBackground), in: shape)
        } else {
            content.background(.bar, in: shape)
        }
    }
}

private struct PlatformBarMaterialFillModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.secondarySystemBackground))
        } else {
            content.background(.bar)
        }
    }
}

private struct PlatformAccessibleGlassCircleModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let controlSize: ControlSize
    var prominent: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            if prominent {
                content
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(controlSize)
            } else {
                content
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(controlSize)
            }
        } else if prominent {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(controlSize)
        } else {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(controlSize)
        }
    }
}

private struct PlatformAccessibleGlassCapsuleModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let controlSize: ControlSize

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
        } else {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .controlSize(controlSize)
        }
    }
}

private struct PlatformComposerFieldChromeModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color(.secondarySystemFill), in: Capsule())
        } else {
            content.glassEffect(.regular.interactive(), in: .capsule)
        }
    }
}

private struct PlatformToolbarAvatarRingModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .overlay {
                    Circle().strokeBorder(Color(.separator), lineWidth: 0.5)
                }
        } else {
            content.glassEffect(.regular.interactive(), in: .circle)
        }
    }
}
