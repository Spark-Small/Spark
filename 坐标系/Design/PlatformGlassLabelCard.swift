//
//  PlatformGlassLabelCard.swift
//  坐标系
//
//  整块 glass 标签卡按钮与度量。
//

import SwiftUI

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

