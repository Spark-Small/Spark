//
//  PlatformFilterChip.swift
//  坐标系
//
//  横向分类 chip：系统 `.glass` / `.glassProminent` + 多色 SF Symbol。
//  图文距：逐枚测量 `labelReservedIconWidth` + 系统 glass `imagePadding`（0 则 footnote.leading）；
//  禁止整条共用过大预留宽（窄图标会被撑开）。
//

import SwiftUI
import UIKit

struct PlatformFilterChipButton: View {
    let title: String
    let systemImage: String
    var isSelected = false
    var symbolColor: Color?
    var accessibilityHint: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            PlatformFilterChipLabel(title: title, systemImage: systemImage, symbolColor: symbolColor)
        }
        .platformSystemCategoryChipStyle(isSelected: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .modifier(PlatformFilterChipAccessibilityHint(hint: accessibilityHint))
    }
}

private struct PlatformFilterChipAccessibilityHint: ViewModifier {
    var hint: String?

    func body(content: Content) -> some View {
        if let hint, !hint.isEmpty {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

struct PlatformFilterChipMenu<Content: View>: View {
    let title: String
    let systemImage: String
    var isSelected = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        Menu(content: content) {
            PlatformFilterChipLabel(title: title, systemImage: systemImage, symbolColor: nil)
        }
        .platformSystemCategoryChipStyle(isSelected: isSelected)
        .sensoryFeedback(.selection, trigger: isSelected)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PlatformFilterChipBar<Content: View>: View {
    /// 嵌在已有 List `contentMargins` 内时设为 `false`，避免双边距。
    var padsHorizontally: Bool = true
    @ViewBuilder var content: Content

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    init(
        padsHorizontally: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.padsHorizontally = padsHorizontally
        self.content = content()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Group {
                if reduceTransparency {
                    chipRow
                } else {
                    GlassEffectContainer {
                        chipRow
                    }
                }
            }
            .padding(.horizontal, padsHorizontally ? nil : 0)
            .padding(.vertical, PlatformConversationListRow.textToSecondarySpacing)
        }
        .scrollContentBackground(.hidden)
        .labelStyle(.titleAndIcon)
    }

    private var chipRow: some View {
        HStack(spacing: PlatformMetrics.inlineControlSpacing) {
            content
        }
    }
}

// MARK: - Label

private struct PlatformFilterChipLabel: View {
    let title: String
    let systemImage: String
    var symbolColor: Color?

    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        } icon: {
            chipIcon
        }
        .labelStyle(.titleAndIcon)
        .labelReservedIconWidth(PlatformFilterChipMetrics.side(for: systemImage))
        .labelIconToTitleSpacing(PlatformFilterChipMetrics.iconToTitleSpacing)
    }

    @ViewBuilder
    private var chipIcon: some View {
        let image = Image(systemName: systemImage)
            .font(.body)
            .imageScale(.medium)
        if let symbolColor {
            image
                .symbolRenderingMode(.palette)
                .foregroundStyle(symbolColor, symbolColor.opacity(0.55))
        } else {
            image.platformContentSymbolStyle()
        }
    }
}

// MARK: - System metrics

private enum PlatformFilterChipMetrics {
    /// 与 `.controlSize(.regular)` 同档：body + medium scale。
    private static var symbolConfiguration: UIImage.SymbolConfiguration {
        UIImage.SymbolConfiguration(textStyle: .body, scale: .medium)
    }

    /// 逐枚符号固有宽，避免整条共用预留把窄图标撑开。
    static func side(for systemImage: String) -> CGFloat {
        if let image = UIImage(systemName: systemImage, withConfiguration: symbolConfiguration) {
            return max(image.size.width, image.size.height)
        }
        return UIFont.preferredFont(forTextStyle: .body).pointSize
    }

    /// glass 按钮图文距；`0` 表示系统默认 → 用 footnote.leading（系统字距，非手写 pt）。
    static var iconToTitleSpacing: CGFloat {
        var configuration = UIButton.Configuration.glass()
        configuration.buttonSize = .medium
        configuration.imagePlacement = .leading
        if configuration.imagePadding > 0 {
            return configuration.imagePadding
        }
        return UIFont.preferredFont(forTextStyle: .footnote).leading
    }
}

// MARK: - System glass capsule

extension View {
    /// 分类 chip：系统 glass 胶囊；选中 glassProminent。降低透明度时回退 bordered。
    func platformSystemCategoryChipStyle(isSelected: Bool) -> some View {
        modifier(PlatformSystemCategoryChipStyle(isSelected: isSelected))
    }
}

private struct PlatformSystemCategoryChipStyle: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var isSelected: Bool

    func body(content: Content) -> some View {
        Group {
            if reduceTransparency {
                if isSelected {
                    content.buttonStyle(.borderedProminent)
                } else {
                    content.buttonStyle(.bordered)
                }
            } else if isSelected {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        }
        .controlSize(.regular)
        .buttonBorderShape(.capsule)
        .tint(isSelected ? Color.accentColor : .primary)
    }
}

#Preview("Filter Chips") {
    ZStack {
        PlatformSurface.groupedPage.ignoresSafeArea()
        PlatformFilterChipBar {
            PlatformFilterChipButton(
                title: "娱乐",
                systemImage: "popcorn.fill",
                action: {}
            )
            PlatformFilterChipButton(
                title: "全部",
                systemImage: "square.grid.2x2.fill",
                isSelected: true,
                action: {}
            )
            PlatformFilterChipButton(
                title: "社交",
                systemImage: "bubble.left.and.bubble.right.fill",
                action: {}
            )
            PlatformFilterChipMenu(
                title: "爱好",
                systemImage: "heart.fill",
                isSelected: false
            ) {
                Button("不限") {}
            }
        }
    }
}
