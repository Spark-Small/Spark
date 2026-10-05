//
//  PlatformActivityChrome.swift
//  坐标系
//
//  活动 CTA / glass 控件（发现页与详情共用）。
//

import SwiftUI

struct PlatformPlaceholderFill: View {
    var body: some View {
        LinearGradient(
            colors: [
                PlatformSurface.tertiaryFill,
                Color(.secondarySystemFill)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: "photo")
                .font(.title2.weight(.bold))
                .foregroundStyle(.secondary)
                .platformSymbolStyle(.hierarchical)
        }
    }
}

extension View {
    /// 主 CTA 胶囊 — 发现卡报名 / 详情底栏报名
    @ViewBuilder
    func activityPrimaryCTA(controlSize: ControlSize = .large) -> some View {
        modifier(PlatformActivityCTAModifier(prominent: true, controlSize: controlSize))
    }

    /// 次要 CTA 胶囊 — glass 次要态，与主 CTA 同家族
    @ViewBuilder
    func activitySecondaryCTA(controlSize: ControlSize = .large) -> some View {
        modifier(PlatformActivityCTAModifier(prominent: false, controlSize: controlSize))
    }

    /// 圆形 glass 图标（关闭、日历、导航、私信、发送）
    @ViewBuilder
    func activityGlassIcon(prominent: Bool = false) -> some View {
        modifier(PlatformActivityGlassIconModifier(prominent: prominent))
    }

    /// 头图小胶囊 glass（相册张数 / 编辑等紧凑控件）
    func activityGlassChip() -> some View {
        modifier(PlatformActivityGlassChipModifier())
    }

    /// 整块 glass 卡片（图标置顶 + 标题副文案，圆角与 Wallet 长条同族）。
    func platformGlassLabelCardStyle(
        controlSize: ControlSize = PlatformToolbarChrome.controlSize
    ) -> some View {
        modifier(PlatformActivityGlassCardModifier(controlSize: controlSize))
    }

    /// 信息 / 次要 glass 胶囊 — 用 `controlSize` 调档（`.regular` 对齐筛选条，`.large` 对齐底栏 CTA）
    func activityGlassCapsule(controlSize: ControlSize = .regular) -> some View {
        modifier(PlatformActivityGlassCapsuleModifier(controlSize: controlSize))
    }
}

// MARK: - Reduce transparency CTA / glass

private struct PlatformActivityCTAModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let prominent: Bool
    let controlSize: ControlSize

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            if prominent {
                content
                    .buttonStyle(.borderedProminent)
                    .controlSize(controlSize)
                    .buttonBorderShape(.capsule)
            } else {
                content
                    .buttonStyle(.bordered)
                    .controlSize(controlSize)
                    .buttonBorderShape(.capsule)
            }
        } else if prominent {
            content
                .buttonStyle(.glassProminent)
                .controlSize(controlSize)
                .buttonBorderShape(.capsule)
        } else {
            content
                .buttonStyle(.glass)
                .controlSize(controlSize)
                .buttonBorderShape(.capsule)
        }
    }
}

private struct PlatformActivityGlassIconModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let prominent: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            if prominent {
                content
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
            } else {
                content
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
            }
        } else if prominent {
            content
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        } else {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
    }
}

private struct PlatformActivityGlassChipModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .buttonStyle(.bordered)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        } else {
            content
                .buttonStyle(.glass)
                .controlSize(.small)
                .buttonBorderShape(.capsule)
        }
    }
}

private struct PlatformActivityGlassCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let controlSize: ControlSize

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle(radius: PlatformMetrics.radiusPoster))
                .controlSize(controlSize)
        } else {
            content
                .buttonStyle(.glass)
                .buttonBorderShape(.roundedRectangle(radius: PlatformMetrics.radiusPoster))
                .controlSize(controlSize)
        }
    }
}

private struct PlatformActivityGlassCapsuleModifier: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let controlSize: ControlSize

    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .buttonStyle(.bordered)
                .controlSize(controlSize)
                .buttonBorderShape(.capsule)
        } else {
            content
                .buttonStyle(.glass)
                .controlSize(controlSize)
                .buttonBorderShape(.capsule)
        }
    }
}

