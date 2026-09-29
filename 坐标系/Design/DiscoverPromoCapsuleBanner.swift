//
//  DiscoverPromoCapsuleBanner.swift
//  坐标系
//
//  坐标系品牌推广胶囊：品牌紫底 + 四叶草 mark + 白字 + chevron。
//  活动 Tab 顶部 Continue 见 `ActivityNextUpBanner` / `ActivityDiscoverPromoBanner`；
//  搭子 Tab「我的预约」见 `BuddyMyBookingsEntryBanner`；底部 Now Playing 见 `DiscoverTabNowPlayingAccessory`。
//  尺寸由 `.controlSize` + UIListContent / chip token 推导，无固定 pt。
//

import SwiftUI

/// 顶部紫胶囊展示内容（文案由 Features 层注入，Design 层不硬编码业务字串）。
struct DiscoverPromoCapsuleContent: Equatable {
    let title: String
    let subtitle: String
}

/// 发现页顶部实心胶囊条（Continue / 推广语义）。
struct DiscoverPromoCapsuleBanner: View {
    let content: DiscoverPromoCapsuleContent
    var fill: Color = PlatformAction.brandAccent
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .body) private var brandMarkSide = 22

    init(
        title: String,
        subtitle: String,
        fill: Color = PlatformAction.brandAccent,
        action: @escaping () -> Void
    ) {
        self.init(
            content: DiscoverPromoCapsuleContent(title: title, subtitle: subtitle),
            fill: fill,
            action: action
        )
    }

    init(
        content: DiscoverPromoCapsuleContent,
        fill: Color = PlatformAction.brandAccent,
        action: @escaping () -> Void
    ) {
        self.content = content
        self.fill = fill
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                BrandCloverMark(size: brandMarkSide)

                VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
                    Text(content.title)
                        .font(titleFont)
                        .lineLimit(DiscoverAccessibility.titleLineLimit(for: dynamicTypeSize))
                        .multilineTextAlignment(.leading)

                    Text(content.subtitle)
                        .font(subtitleFont)
                        .lineLimit(DiscoverAccessibility.metaLineLimit(for: dynamicTypeSize))
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(.white)

                Spacer(minLength: PlatformMetrics.minContentGap)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .buttonStyle(DiscoverPromoCapsuleButtonStyle(fill: fill))
    }

    private var titleFont: Font {
        .subheadline.weight(.semibold)
    }

    private var subtitleFont: Font {
        .footnote
    }
}

private struct DiscoverPromoCapsuleButtonStyle: ButtonStyle {
    var fill: Color
    @Environment(\.controlSize) private var controlSize

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(fill, in: Capsule())
            .contentShape(Capsule())
            .opacity(configuration.isPressed ? 0.88 : 1)
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

// MARK: - Tab bottom accessory

/// 发现 Tab 底部 Now Playing 附件（`tabViewBottomAccessory`）。
struct DiscoverTabNowPlayingAccessory<Icon: View>: View {
    let title: String
    var subtitle: String? = nil
    var footnote: String? = nil
    var trailingActionTitle: String
    var trailingAccessibilityLabel: String
    @ViewBuilder var icon: () -> Icon
    var onTap: () -> Void
    var onTrailingAction: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    var body: some View {
        accessoryRow
            .padding(.horizontal, PlatformConversationListRow.horizontalInset)
            .padding(.vertical, PlatformConversationListRow.verticalInset)
    }

    private var accessoryRow: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            Button(action: onTap) {
                HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                    icon()

                    PlatformListTextColumn(
                        primary: title,
                        secondary: subtitle,
                        footnote: showsFootnote ? footnote : nil,
                        primaryLineLimit: 1,
                        secondaryLineLimit: 1,
                        footnoteLineLimit: 1
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            trailingControl
        }
    }

    private var showsFootnote: Bool {
        switch placement {
        case .inline:
            return false
        case .expanded, .none:
            return true
        @unknown default:
            return true
        }
    }

    private var trailingControl: some View {
        Button(trailingActionTitle, action: onTrailingAction)
            .activityGlassCapsule(controlSize: PlatformToolbarChrome.controlSize)
            .accessibilityLabel(trailingAccessibilityLabel)
    }
}

#Preview("下一场 Continue") {
    DiscoverPromoCapsuleBanner(
        content: DiscoverPromoCapsuleContent(
            title: "剧本杀：情感本",
            subtitle: "下一场 · 还有 2 项准备没完成 · 今天 14:00 出发"
        ),
        action: {}
    )
    .discoverBrowseContentInset()
    .padding()
}

#Preview("发现引导") {
    DiscoverPromoCapsuleBanner(
        content: DiscoverPromoCapsuleContent(
            title: "找一场一起玩",
            subtitle: "浏览推荐，或自己发起活动"
        ),
        action: {}
    )
    .discoverBrowseContentInset()
    .padding()
}
