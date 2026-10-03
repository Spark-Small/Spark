//
//  DiscoverBrowseLayout.swift
//  坐标系
//
//  发现页分区组件（HIG 对齐契约）：
//  - 单一水平对齐线：标题 / Hero / 竖向列表 / 横滑轨首卡共用 `PlatformMetrics.contentInset`
//    （= 系统 subtitleCell leading）。禁止「页边 + 行内边」双重叠。
//  - 分区间距：`sectionSpacing`；标题 ↔ 内容：`sectionHeaderSpacing`
//  - 卡内叠层文案用 `heroStackedTextInset` / `captionBadgeInset`
//    （相对卡片边缘，由系统列表 margin 推导；不是页边 `contentInset`）
//  - Form/List 表单页交给系统 margins；全宽媒体行用零 inset，相关轨用负 inset + Rail 回补页边
//  - 标题与 trailing 同一行；副标题可选下一行；标题旁 chevron 可点时 =「查看全部」
//  - 横滑：ScrollView + scrollTargetLayout + viewAligned + contentMargins
//

import SwiftUI

// MARK: - Section title

/// 分区标题行：左标题（可选可点 chevron），右 trailing 同水平
struct DiscoverSectionTitleRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var showsChevron = false
    /// 提供后标题 + chevron 成为「查看全部」按钮
    var onSeeAll: (() -> Void)? = nil
    var showsHorizontalInset = true
    @ViewBuilder var trailing: () -> Trailing

    private var revealsChevron: Bool { showsChevron || onSeeAll != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionSubtitleSpacing) {
            HStack(alignment: .center, spacing: PlatformMetrics.sectionTitleClusterSpacing) {
                titleCluster
                Spacer(minLength: PlatformMetrics.sectionTitleClusterSpacing)
                trailing()
            }

            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(onSeeAll != nil)
            }
        }
        .padding(.horizontal, showsHorizontalInset ? PlatformMetrics.contentInset : 0)
    }

    @ViewBuilder
    private var titleCluster: some View {
        let label = HStack(spacing: PlatformMetrics.sectionChevronSpacing) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            if revealsChevron {
                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }

        if let onSeeAll {
            Button(action: onSeeAll) { label }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .padding(.vertical, PlatformMetrics.sectionChevronSpacing)
                .accessibilityLabel("查看全部，\(title)")
                .accessibilityHint(subtitle ?? "打开完整列表")
        } else {
            label
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

extension DiscoverSectionTitleRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        onSeeAll: (() -> Void)? = nil,
        showsHorizontalInset: Bool = true
    ) {
        self.init(
            title: title,
            subtitle: subtitle,
            showsChevron: showsChevron,
            onSeeAll: onSeeAll,
            showsHorizontalInset: showsHorizontalInset
        ) {
            EmptyView()
        }
    }
}

// MARK: - Section chrome

/// 分区容器：标题与内容间距固定为 sectionHeaderSpacing
struct DiscoverBrowseSection<Header: View, Content: View>: View {
    @ViewBuilder var header: () -> Header
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            header()
            content()
        }
    }
}

extension DiscoverBrowseSection where Header == DiscoverSectionTitleRow<EmptyView> {
    init(
        title: String,
        subtitle: String? = nil,
        showsChevron: Bool = false,
        onSeeAll: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            header: {
                DiscoverSectionTitleRow(
                    title: title,
                    subtitle: subtitle,
                    showsChevron: showsChevron,
                    onSeeAll: onSeeAll
                )
            },
            content: content
        )
    }
}

// MARK: - Horizontal rails

/// 横滑轨道：官方 scrollTargetLayout + viewAligned
/// Reduce Motion 时关闭吸附，保留普通横滑（滚动本身不算装饰动效）
///
/// 水平页边 = `PlatformMetrics.contentInset`（系统 subtitleCell leading）。
/// 嵌在已带 `contentMargins` 的 List 行内时，行应负 inset 撑满，由本组件提供唯一页边。
struct DiscoverHorizontalRail<Content: View>: View {
    var spacing: CGFloat = PlatformMetrics.railCardSpacing
    var appliesHorizontalMargins: Bool = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: spacing) {
                content()
            }
            .modifier(DiscoverRailSnapLayoutModifier(enabled: !reduceMotion))
        }
        .modifier(DiscoverRailHorizontalMarginsModifier(enabled: appliesHorizontalMargins))
        .modifier(DiscoverRailSnapBehaviorModifier(enabled: !reduceMotion))
    }
}

private struct DiscoverRailHorizontalMarginsModifier: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.contentMargins(
                .horizontal,
                PlatformMetrics.contentInset,
                for: .scrollContent
            )
        } else {
            content
        }
    }
}

private struct DiscoverRailSnapLayoutModifier: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollTargetLayout()
        } else {
            content
        }
    }
}

private struct DiscoverRailSnapBehaviorModifier: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollTargetBehavior(.viewAligned)
        } else {
            content
        }
    }
}

// MARK: - Page chrome

extension View {
    /// 发现类 ScrollView 页：分组底 + 底 safe inset；默认顶边 soft scroll edge（官方栏下滚动交互）。
    /// - Parameter softTopEdge: 是否启用顶边 soft scroll edge。
    func discoverBrowseScrollChrome(softTopEdge: Bool = true) -> some View {
        scrollDismissesKeyboard(.interactively)
            .modifier(DiscoverBrowseSoftTopEdgeModifier(enabled: softTopEdge))
            .background(PlatformSurface.groupedPage)
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: PlatformMetrics.sectionSpacing)
            }
    }

    /// 非横滑内容（Hero、竖向列表）：与分区标题 / 横滑轨首卡共用 `contentInset` 对齐线。
    /// 勿再叠一层 Features 内的水平 padding，否则滚动时会出现第二条对齐线。
    func discoverBrowseContentInset() -> some View {
        padding(.horizontal, PlatformMetrics.contentInset)
    }

    /// 发现页主列：顶/底页边 + 撑满；**分区间距**由调用方内层 `LazyVStack(spacing: sectionSpacing)` 提供。
    /// 滚动锚点须放在外层 `VStack(spacing: 0)`，勿与首块内容同处带 `sectionSpacing` 的栈（否则大标题下多一段留白）。
    func discoverBrowsePageColumn() -> some View {
        frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, PlatformMetrics.sectionHeaderSpacing)
            .padding(.bottom, PlatformMetrics.sectionSpacing)
    }
}

extension View {
    /// Form 内全宽媒体行：清掉系统行边距，由媒体自身 bleed。
    func platformFullBleedMediaFormRow() -> some View {
        listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }

    /// Form 内相关活动 / 最近浏览横滑轨：负水平 inset，页边交给 `DiscoverHorizontalRail`。
    func platformFormRelatedRailRow() -> some View {
        listRowInsets(
            EdgeInsets(
                top: PlatformMetrics.sectionHeaderSpacing,
                leading: -PlatformMetrics.contentInset,
                bottom: PlatformMetrics.sectionHeaderSpacing,
                trailing: -PlatformMetrics.contentInset
            )
        )
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

private struct DiscoverBrowseSoftTopEdgeModifier: ViewModifier {
    var enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
    }
}
