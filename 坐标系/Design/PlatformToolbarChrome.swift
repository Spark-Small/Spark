//
//  PlatformToolbarChrome.swift
//  坐标系
//
//  Photos 式顶栏：圆形 glass 侧钮 + 双行胶囊 principal；详情底栏 safeAreaBar。
//

import SwiftUI

/// Photos 顶栏 chrome：两侧圆形 + 中间双行胶囊，同一 `controlSize` 对齐高度
enum PlatformToolbarChrome {
    /// 系统 toolbar 默认档；与两侧圆形 glass 同高
    static var controlSize: ControlSize { .regular }
    /// Photos 中间主行（如「昨天」）
    static var principalTitleFont: Font { .subheadline.weight(.semibold) }
    /// Photos 中间次行（如「13:16」）
    static var principalSubtitleFont: Font { .caption2 }
    static var principalLineSpacing: CGFloat { 0 }
}

/// Photos 式中间胶囊文案：上下两行、居中
struct PlatformToolbarPrincipalCaption: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: PlatformToolbarChrome.principalLineSpacing) {
            Text(title)
                .font(PlatformToolbarChrome.principalTitleFont)
                .lineLimit(1)
            Text(subtitle)
                .font(PlatformToolbarChrome.principalSubtitleFont)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .multilineTextAlignment(.center)
    }
}

extension View {
    /// 导航栏图标：系统语义色（`.primary`），隔离页面品牌 `.tint`。
    func platformNavigationBarItemChrome() -> some View {
        tint(.primary)
    }

    /// 处理中遮罩：Metrics 只在 Design 消费；降低透明度时用不透明底。
    func platformProcessingOverlayChrome() -> some View {
        self
            .padding(PlatformMetrics.processingOverlayPadding)
            .platformUltraThinMaterialBackground(in: PlatformMetrics.processingOverlayShape)
    }

    /// 详情主转化底栏：iOS 26 `safeAreaBar`，下滑可随 Tab 收纳
    func platformDetailBottomBar<Bar: View>(
        @ViewBuilder bar: () -> Bar
    ) -> some View {
        safeAreaBar(edge: .bottom, spacing: 0, content: bar)
    }

    /// 会话 / 帖评 Composer 底栏：官方 `safeAreaBar`（滚动边缘渐进模糊，勿用 `safeAreaInset` 硬切出第三块长方形）。
    func platformMessageComposerBottomBar<Bar: View>(
        @ViewBuilder bar: () -> Bar
    ) -> some View {
        safeAreaBar(edge: .bottom, spacing: 0, content: bar)
    }

    /// 分类 chip 顶条（可选）：与导航栏 / soft scroll edge 材质联动。
    /// Tab 根若叠 `searchable`，`safeAreaBar(.top)` 易被吃掉高度；改用 `safeAreaInset`。
    /// 广场 Feed 已改为 List 首 Section 挂载 chip（对齐通知中心），一般不再使用本 API。
    func platformCategoryChipTopBar<Bar: View>(
        @ViewBuilder bar: () -> Bar
    ) -> some View {
        safeAreaInset(edge: .top, spacing: 0) {
            bar()
                .frame(maxWidth: .infinity)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// 详情底栏悬浮 CTA 水平边距（Features 不手写 token）
    func activityDetailBottomBarChrome() -> some View {
        self.padding(.horizontal, PlatformMetrics.contentInset)
    }

    /// 媒体角上控件 inset（头图 chip / 相册编辑钮）
    func platformMediaChromeInset() -> some View {
        self.padding(PlatformMetrics.mediaChromeInset)
    }

    /// 相关活动缩略图
    func platformRelatedThumb() -> some View {
        modifier(PlatformRelatedThumbModifier())
    }

    /// 详情地图预览高度 + 媒体圆角
    func platformDetailMapPreview() -> some View {
        self
            .frame(height: PlatformMetrics.detailMapHeight)
            .clipShape(PlatformMetrics.mediaShape)
    }
}

private struct PlatformRelatedThumbModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let side = dynamicTypeSize.detailRelatedThumbSide
        content
            .frame(width: side, height: side)
            .clipShape(PlatformMetrics.mediaShape)
    }
}
