//
//  PlatformActivityChrome.swift
//  坐标系
//
//  活动 / 发现 CTA、glass 控件、材质 chip、角标与占位图。
//

import SwiftUI

/// 占位图：仅用系统 fill / tint，不用 HSB
struct PlatformPlaceholderFill: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(.tertiarySystemFill),
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

    // MARK: Activity CTA / Glass（发现页与详情共用系统 glass，不用品牌墨色）

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

// MARK: - Glass label card

/// 整块 glass 卡片：图标置顶 + 标题 + 副文案，左对齐纵向堆叠。
struct PlatformGlassLabelCardButton: View {
    let title: String
    var subtitle: String? = nil
    let systemImage: String
    var symbolChrome: PlatformSymbolChrome = .multicolor
    var accessibilityLabel: String? = nil
    var titleLineLimit: Int? = nil
    var subtitleLineLimit: Int? = nil
    var controlSize: ControlSize = PlatformToolbarChrome.controlSize
    let action: () -> Void

    @ScaledMetric(relativeTo: .title2) private var iconSide = PlatformGlassLabelCardMetrics.iconSide

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: PlatformGlassLabelCardMetrics.contentSpacing) {
                Image(systemName: systemImage)
                    .font(.system(size: iconSide, weight: .regular))
                    .platformSymbolStyle(symbolChrome)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: PlatformMetrics.hairlineSpacing) {
                    Text(title)
                        .font(PlatformGlassLabelCardMetrics.titleFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(resolvedTitleLineLimit)

                    if let subtitle {
                        Text(subtitle)
                            .font(PlatformGlassLabelCardMetrics.subtitleFont)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(resolvedSubtitleLineLimit)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .padding(PlatformGlassLabelCardMetrics.padding)
        }
        .platformGlassLabelCardStyle(controlSize: controlSize)
        .accessibilityLabel(accessibilityLabel ?? combinedAccessibilityLabel)
    }

    private var resolvedTitleLineLimit: Int? {
        titleLineLimit ?? (subtitle == nil ? 2 : PlatformGlassLabelCardMetrics.titleLineLimit)
    }

    private var resolvedSubtitleLineLimit: Int? {
        subtitleLineLimit ?? PlatformGlassLabelCardMetrics.subtitleLineLimit
    }

    private var combinedAccessibilityLabel: String {
        if let subtitle {
            return "\(title)，\(subtitle)"
        }
        return title
    }
}

enum PlatformGlassLabelCardMetrics {
    static var iconSide: CGFloat { 30 }
    static var padding: CGFloat { PlatformMetrics.contentInset }
    static var contentSpacing: CGFloat { PlatformMetrics.cardInfoSpacing }
    static var subtitleLineLimit: Int { 1 }

    static var titleLineLimit: Int { 1 }
    static var titleFont: Font { .subheadline.weight(.semibold) }
    static var subtitleFont: Font { .footnote }
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

private extension View {
    @ViewBuilder
    func platformMaterialTagChrome(isSelected: Bool) -> some View {
        if isSelected {
            self
                .platformBarMaterialBackground(in: Capsule())
                .overlay {
                    Capsule().strokeBorder(Color.accentColor, lineWidth: 1)
                }
        } else {
            self
                .background(Color(.tertiarySystemFill), in: Capsule())
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
