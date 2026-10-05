//
//  PlatformActivityChipsBadges.swift
//  坐标系
//
//  材质 chip、角标与标签 chrome。
//

import SwiftUI

extension View {
    /// 静态标签：材质胶囊，规格与角标一致（系统 caption2）
    func platformGlassTag() -> some View {
        self
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
            .platformThinMaterialBackground(in: Capsule())
    }

    /// 材质背景 chip 按钮：高度与筛选条一致（`.controlSize(.regular)`）
    func platformMaterialChipStyle(isSelected: Bool) -> some View {
        buttonStyle(PlatformMaterialChipStyle(isSelected: isSelected))
            .controlSize(.regular)
            .buttonBorderShape(.capsule)
            .id(isSelected)
    }
}

// MARK: - Material chip button

private struct PlatformMaterialChipStyle: ButtonStyle {
    var isSelected: Bool
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(chipFont)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .platformMaterialTagChrome(isSelected: isSelected)
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
    }

    private var chipFont: Font {
        switch controlSize {
        case .mini, .small:
            return .caption.weight(isSelected ? .semibold : .medium)
        default:
            return .subheadline.weight(isSelected ? .semibold : .medium)
        }
    }

    private var horizontalPadding: CGFloat {
        switch controlSize {
        case .mini: PlatformMetrics.chipPaddingHorizontalMini
        case .small: PlatformMetrics.chipPaddingHorizontalSmall
        case .large, .extraLarge: PlatformMetrics.chipPaddingHorizontalLarge
        default: PlatformMetrics.chipPaddingHorizontalRegular
        }
    }

    private var verticalPadding: CGFloat {
        switch controlSize {
        case .mini: PlatformMetrics.chipPaddingVerticalMini
        case .small: PlatformMetrics.chipPaddingVerticalSmall
        case .large: PlatformMetrics.chipPaddingVerticalLarge
        case .extraLarge: PlatformMetrics.chipPaddingVerticalExtraLarge
        default: PlatformMetrics.chipPaddingVerticalRegular
        }
    }
}

extension View {
    /// 可选标签 / chip 背景：选中走 bar 材质 + tint 描边，未选中 tertiaryFill。
    @ViewBuilder
    func platformMaterialTagChrome(isSelected: Bool) -> some View {
        if isSelected {
            self
                .platformBarMaterialBackground(in: Capsule())
                .overlay {
                    Capsule().strokeBorder(PlatformStatus.accent, lineWidth: 1)
                }
        } else {
            self
                .background(PlatformSurface.tertiaryFill, in: Capsule())
        }
    }
}

/// 角标 / 状态·社交证明标签（非按钮）：系统 `.caption2`，与主 CTA 的 ControlSize 分离
struct PlatformCaptionBadge: View {
    enum Chrome {
        /// 封面叠字：细材质
        case material
        /// 状态色底（快满 / 已参加）
        case tint(Color)
    }

    let title: String
    var chrome: Chrome = .material
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
            .background { background }
    }

    private var foreground: Color {
        switch chrome {
        case .material: .primary
        case .tint: .white
        }
    }

    @ViewBuilder
    private var background: some View {
        switch chrome {
        case .material:
            if reduceTransparency {
                Capsule().fill(Color(.secondarySystemBackground))
            } else {
                Capsule().fill(.thinMaterial)
            }
        case .tint(let color):
            Capsule().fill(color.opacity(0.92))
        }
    }
}

/// 媒体封面左上角标壳：统一 inset / 点击穿透 / 深色封面配色
struct PlatformMediaCaptionBadge: View {
    var title: String
    var tint: Color? = nil
    var onMedia = true

    var body: some View {
        Group {
            if let tint {
                PlatformCaptionBadge(title: title, chrome: .tint(tint))
            } else {
                PlatformCaptionBadge(title: title, chrome: .material)
            }
        }
        .padding(PlatformMetrics.captionBadgeInset)
        .colorScheme(onMedia ? .dark : .light)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
