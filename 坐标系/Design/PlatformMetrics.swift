//
//  PlatformMetrics.swift
//  坐标系
//
//  系统推导间距 / 圆角 / 形状 token（Dynamic Type + UIListContent）。
//

import SwiftUI
import UIKit

enum PlatformMetrics {
    // MARK: - 系统推导网格（Dynamic Type + UIListContent）

    /// Body 半宽网格基准；随内容字号变化（默认 ≈8–9）
    private static var grid: CGFloat {
        let body = UIFont.preferredFont(forTextStyle: .body).pointSize
        return max(4, (body * 0.5).rounded(.toNearestOrAwayFromZero))
    }

    private static func g(_ n: CGFloat) -> CGFloat {
        (grid * n).rounded(.toNearestOrAwayFromZero)
    }

    /// 系统列表水平边距 = Layout Margins（VC 下限 ∩ 表/subtitleCell leading，≥16）
    private static var systemListLeading: CGFloat {
        Self.resolvedTableHorizontalInset()
    }

    nonisolated(unsafe) private static var cachedTableHorizontalInset: [String: CGFloat] = [:]

    private static func resolvedTableHorizontalInset(
        for category: UIContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    ) -> CGFloat {
        let key = category.rawValue
        if let cached = cachedTableHorizontalInset[key] { return cached }

        var resolved: CGFloat = 16
        UITraitCollection(preferredContentSizeCategory: category).performAsCurrent {
            let subtitleLeading = UIListContentConfiguration.subtitleCell()
                .directionalLayoutMargins.leading
            if subtitleLeading > 0 {
                resolved = max(subtitleLeading, 16)
            }
        }
        cachedTableHorizontalInset[key] = resolved
        return resolved
    }

    private static var systemListVertical: CGFloat {
        let top = UIListContentConfiguration.subtitleCell().directionalLayoutMargins.top
        if top > 0 { return top }
        return UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    /// 系统 List 分节顶距（`UITableView.sectionHeaderTopPadding`）
    nonisolated(unsafe) private static var cachedSectionHeaderTopPadding: [String: CGFloat] = [:]

    private static func resolvedTableSectionHeaderTopPadding(
        for category: UIContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    ) -> CGFloat {
        let key = category.rawValue
        if let cached = cachedSectionHeaderTopPadding[key] { return cached }

        var resolved: CGFloat = 0
        UITraitCollection(preferredContentSizeCategory: category).performAsCurrent {
            resolved = systemListVertical
            if resolved <= 0 {
                resolved = UIFont.preferredFont(forTextStyle: .title2).lineHeight
            }
        }
        cachedSectionHeaderTopPadding[key] = resolved
        return resolved
    }

    /// 系统 subtitleCell 主副文垂直间距
    private static var systemTextToSecondaryPadding: CGFloat {
        let padding = UIListContentConfiguration.subtitleCell().textToSecondaryTextVerticalPadding
        if padding > 0 { return padding }
        return UIFont.preferredFont(forTextStyle: .caption2).leading
    }

    /// 系统 subtitleCell 图↔文间距
    private static var systemImageToTextPadding: CGFloat {
        let padding = UIListContentConfiguration.subtitleCell().imageToTextPadding
        if padding > 0 { return padding }
        return UIFont.preferredFont(forTextStyle: .body).pointSize
    }

    private static var caption2: CGFloat {
        UIFont.preferredFont(forTextStyle: .caption2).pointSize
    }

    private static var caption2LineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .caption2).lineHeight
    }

    private static var bodyPointSize: CGFloat {
        UIFont.preferredFont(forTextStyle: .body).pointSize
    }

    // MARK: - Insets / page

    /// 页面水平边距 = 系统列表 leading
    static var contentInset: CGFloat { systemListLeading }
    /// 我的行程主列可读宽（iPad / 横屏居中，对齐 HIG readable width）
    static var journeyContentMaxWidth: CGFloat { 560 }
    /// 封面角标边距（相对卡片边）：系统列表行垂直 margin
    static var captionBadgeInset: CGFloat { max(g(1), systemListVertical) }
    /// 媒体信息栏 / 卡内叠字相对卡片边缘的 inset（与页边同值，语义区分「卡内」）。
    static var mediaChromeInset: CGFloat { contentInset }
    /// 卡内叠层文案 ↔ 卡片边缘（非页边）：列表垂直 margin 与半页边取大，随 Dynamic Type
    static var heroStackedTextInset: CGFloat {
        let halfLeading = (contentInset * 0.5).rounded(.toNearestOrAwayFromZero)
        return max(systemListVertical, halfLeading, g(1))
    }
    /// 纪念票分享导出宽：`contentInset × 24`（紧凑屏内容宽量级，非裸 390）
    static var mementoShareExportWidth: CGFloat {
        max(320, (contentInset * 24).rounded(.toNearestOrAwayFromZero))
    }
    /// 纪念票分享圆角 = 卡片 continuous 圆角
    static var mementoShareCornerRadius: CGFloat { radiusCard }
    /// 票面 / 分享图四叶草标边长（title3 字号量级）
    static var cloverBrandMarkSide: CGFloat {
        max(
            g(2.5),
            UIFont.preferredFont(forTextStyle: .title3).pointSize.rounded(.toNearestOrAwayFromZero)
        )
    }
    /// 发现页滚动顶边（问候头）
    static var pageTopInset: CGFloat { g(0.5) }
    /// 头像叠压重叠比例（相对头像边长）
    static var avatarStackOverlapFactor: CGFloat { 0.28 }
    static func avatarStackSpacing(avatarSide: CGFloat) -> CGFloat {
        -(avatarSide * avatarStackOverlapFactor)
    }
    /// 参加 / 发布成功插图宽高比
    static var successIllustrationAspectRatio: CGFloat { 7.0 / 3.0 }
    /// 成功插图相对 `journeyContentMaxWidth` 的最大宽度系数
    static var successIllustrationMaxWidthFactor: CGFloat { 0.5 }

    // MARK: - Rhythm（分区间距取系统 List 量，不用自定义 g 倍数）

    /// 发现大分区间距 = 系统 `sectionHeaderTopPadding`
    static var sectionSpacing: CGFloat { resolvedTableSectionHeaderTopPadding() }
    /// 分区标题 ↔ 内容 = 系统列表行垂直 margin
    static var sectionHeaderSpacing: CGFloat { systemListVertical }
    /// 同行紧邻控件间距 = 系统 subtitleCell `imageToTextPadding`
    static var inlineControlSpacing: CGFloat { systemImageToTextPadding }
    static var discoverCardSpacing: CGFloat { g(1.75) }
    static var railCardSpacing: CGFloat { g(1.5) }
    static var stackedMediaSpacing: CGFloat { g(1) }
    static var cardFooterSpacing: CGFloat { g(1.5) }
    static var emptyStateVerticalPadding: CGFloat { g(6) }
    static var captionBadgePaddingHorizontal: CGFloat { max(4, (caption2 * 0.55).rounded()) }
    static var captionBadgePaddingVertical: CGFloat { max(2, (caption2 * 0.25).rounded()) }
    /// 标题 ↔ 副标题 = 系统 subtitle 主副文间距
    static var sectionSubtitleSpacing: CGFloat { systemTextToSecondaryPadding }
    static var heroActionMinWidth: CGFloat { g(9.5) }
    static var rankBadgeLeading: CGFloat { g(0.75) }
    static var rankBadgeTop: CGFloat { g(0.5) }
    static var detailBottomBarTopPadding: CGFloat { g(1.25) }
    static var detailBottomBarBottomPadding: CGFloat { g(1) }
    static var detailBottomBarSpacing: CGFloat { g(1.25) }
    static var detailHeroAspectRatio: CGFloat { featuredCardAspectRatio }
    static var processingOverlayShape: RoundedRectangle { cardShape }
    static var detailRowSpacing: CGFloat { g(1.5) }
    static var detailTightSpacing: CGFloat { g(1.25) }
    static var detailCompactSpacing: CGFloat { g(1) }
    static var detailMicroSpacing: CGFloat { g(0.75) }
    static var detailMapHeight: CGFloat { g(15) }
    /// 相关缩略图 ≈ 列表标准头像 × 1.85（无 Environment 时用当前 trait 回退）
    static var detailRelatedThumb: CGFloat {
        DynamicTypeSize(
            uiContentSizeCategory: UITraitCollection.current.preferredContentSizeCategory
        ).detailRelatedThumbSide
    }

    static func detailRelatedThumb(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.detailRelatedThumbSide
    }
    /// 紧凑叠字间距 = 系统 subtitleCell 主↔副文垂直间距（非自建 grid）。
    static var hairlineSpacing: CGFloat { systemTextToSecondaryPadding }
    static var formRowVerticalPadding: CGFloat {
        max(2, (systemListVertical * 0.35).rounded(.toNearestOrAwayFromZero))
    }
    /// 最小内容间隙 = 系统 subtitleCell 图↔文间距（列表行内相邻内容节奏）。
    static var minContentGap: CGFloat { systemImageToTextPadding }
    static var galleryEditorThumb: CGFloat { g(11) }
    static var galleryRemoveBadgeOffset: CGFloat { g(0.75) }
    static var orderStatusPaddingHorizontal: CGFloat { g(1) }
    static var orderStatusPaddingVertical: CGFloat { g(0.5) }
    static var processingOverlayPadding: CGFloat { g(3) }
    static var ctaSubtitleSpacing: CGFloat { max(2, g(0.25)) }

    // MARK: - Messages chrome

    /// 在线 / 未读角标直径
    static var messagePresenceDotSize: CGFloat {
        max(g(1), (caption2 * 0.85).rounded(.toNearestOrAwayFromZero))
    }

    /// 头像角标偏移（未读点 / 在线点）
    static var avatarBadgeOffset: CGFloat { g(0.25) }

    /// 头像角标描边
    static var avatarBadgeStroke: CGFloat { 1.5 }

    /// 回复预览左侧强调条宽度
    static var messageReplyAccentWidth: CGFloat { hairlineSpacing }

    // MARK: - Radii（continuous；`g()` 随 body 字号，对齐 Dynamic Type）

    static var radiusMedia: CGFloat { g(1.5) }
    static var radiusCard: CGFloat { g(2.5) }
    static var detailBlockSpacing: CGFloat { discoverCardSpacing }
    /// 卡宽高比为构图比，非 pt
    static var activityCardAspectRatio: CGFloat { 16 / 9 }
    static var continueCardAspectRatio: CGFloat { 16 / 9 }
    /// 「我的」个人内容库竖海报（宽:高），参考 Apple TV 榜单小卡。
    static var profileLibraryCardAspectRatio: CGFloat { 2 / 3 }
    /// 榜单 / 圈子 / 语音厅竖海报（宽:高）；略扁于经典 2:3，降低货架轨高
    static var posterCardAspectRatio: CGFloat { 3 / 4 }
    /// 精选 Hero / 详情头图 / 广场 Feed·详情媒体（宽:高）
    static var featuredCardAspectRatio: CGFloat { 4 / 5 }
    /// 广场帖媒体（宽:高）= 精选 Hero 同族 4:5
    static var communityMediaAspectRatio: CGFloat { featuredCardAspectRatio }
    /// 活动精选轨 / 焦点大卡（宽:高）；与跟进、热场同为 16:9，避免全宽竖卡过高
    static var editorialCardAspectRatio: CGFloat { 16 / 9 }
    /// 搭子精选 Hero（宽:高）= 活动精选同族 4:5；全宽单卡见 `BuddyFeaturedCard`
    static var personFeaturedCardAspectRatio: CGFloat { featuredCardAspectRatio }
    /// 搭子人像竖卡（宽:高）— 详情头图
    static var personCardAspectRatio: CGFloat { 9 / 16 }
    /// 搭子发现网格 / 精选竖卡（宽:高）= 系统海报族 `posterCardAspectRatio`
    static var personGridCardAspectRatio: CGFloat { posterCardAspectRatio }
    /// 同好 / 陪玩发现网格列数
    static var personGridColumnCount: Int { 2 }
    static var radiusEditorial: CGFloat { g(3) }
    static var radiusPoster: CGFloat { g(1.75) }
    /// 轨可见列数：页边由 `DiscoverHorizontalRail.contentMargins` 承担，卡宽相对「页边内可视宽」
    /// 焦点大卡 / 跟进 / 热场：一屏 1 卡全宽
    static var discoverRailFullWidthColumnCount: Int { 1 }
    /// 榜单海报：一屏 2 卡全宽
    static var posterRailColumnCount: Int { 2 }
    /// 「我的活动 / 发布」凭证横卡：系统相对容器一屏两列。
    static var profileActivityCredentialRailColumnCount: Int { 2 }
    /// 「我的 → 我的陪玩」凭证竖卡：一屏约三张完整卡，并露出第四张。
    static var profileBookingCredentialRailVisibleFraction: CGFloat { 0.29 }
    /// 个人内容库竖海报（圈子）：一屏约三张完整卡，并露出第四张提示横滑。
    static var profileLibraryRailVisibleFraction: CGFloat { 0.29 }
    static var cardInfoSpacing: CGFloat { g(0.75) }
    static var metaSymbolSpacing: CGFloat { g(0.75) }
    /// 分区标题簇水平间距 = 系统图文间距
    static var sectionTitleClusterSpacing: CGFloat { systemImageToTextPadding }
    /// chevron 与标题间距 = 系统主副文间距
    static var sectionChevronSpacing: CGFloat { systemTextToSecondaryPadding }
    static var seeAllRankColumnWidth: CGFloat { g(4.5) }
    /// 双 CTA 场景右留白（搭子卡）
    static var heroDualActionTrailingReserve: CGFloat { g(21) }

    /// 搭子详情相册高度
    static var buddyGalleryHeight: CGFloat { g(52) }

    // MARK: - Material chip（ControlSize → grid）

    static var chipPaddingHorizontalMini: CGFloat { g(1) }
    static var chipPaddingHorizontalSmall: CGFloat { g(1.25) }
    static var chipPaddingHorizontalRegular: CGFloat { g(1.5) }
    static var chipPaddingHorizontalLarge: CGFloat { contentInset }
    static var chipPaddingVerticalMini: CGFloat { max(2, g(0.25)) }
    static var chipPaddingVerticalSmall: CGFloat { formRowVerticalPadding }
    static var chipPaddingVerticalRegular: CGFloat { max(4, (caption2 * 0.55).rounded()) }
    static var chipPaddingVerticalLarge: CGFloat { g(1.25) }
    static var chipPaddingVerticalExtraLarge: CGFloat { g(1.5) }

    /// eventTicket strip 官方比例 375×98pt。
    static func walletPassEventStripHeight(cardWidth: CGFloat) -> CGFloat {
        guard cardWidth > 0 else { return 98 }
        return (cardWidth * (98.0 / 375.0)).rounded(.toNearestOrAwayFromZero)
    }

    /// Wallet 票面宽高比：与系统竖海报同一规格（3:4）。
    static var walletPassFaceAspectRatio: CGFloat { posterCardAspectRatio }
    /// 行程页 QR 边长：按卡宽比例并设可扫下限（Pass 条码区宜 ≥ 约 1″ 宽）。
    static func walletPassJourneyQRCodeSide(cardWidth: CGFloat) -> CGFloat {
        guard cardWidth > 0 else { return 128 }
        let inset = walletPassChromeInset * 2
        let maxSide = max(cardWidth - inset, 96)
        let proportional = (cardWidth * 0.42).rounded(.toNearestOrAwayFromZero)
        return min(max(proportional, 120), maxSide)
    }
    /// 长条凭证条高下限：顶栏 / 底栏字阶 + 系统主副文间距 + Form 行垂直 padding。
    static func walletPassStripBarHeight(navigationBarButtonSide: CGFloat) -> CGFloat {
        let pad = formRowVerticalPadding
        let title = UIFont.preferredFont(forTextStyle: .body).lineHeight
        let meta = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let header = title + systemTextToSecondaryPadding + meta
        let footerLabel = UIFont.preferredFont(forTextStyle: .caption2).lineHeight
        let footerValue = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        let footerText = footerLabel + systemTextToSecondaryPadding + footerValue
        let capsule = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
            + chipPaddingVerticalSmall * 2
        let footer = max(footerText, navigationBarButtonSide, capsule)
        return (pad + header + sectionSubtitleSpacing + footer + pad)
            .rounded(.toNearestOrAwayFromZero)
    }
    /// 票面四角字段边距（顶栏 / 条码 / 地点共用，保证左右对齐）
    static var walletPassChromeInset: CGFloat { captionBadgeInset }
    /// 条码区内边距（白底相对码面；对齐系统紧凑控件边距）。
    static var walletPassBarcodePadding: CGFloat { captionBadgeInset }
    /// 展开票面 QR 码面边长：与底栏 band 同高减去条码内边距（_scan 尺寸，非铺满宽条）。
    static func walletPassQRCodeSide(navigationBarButtonSide: CGFloat) -> CGFloat {
        let band = walletPassFooterBandHeight(navigationBarButtonSide: navigationBarButtonSide)
        return max(
            band - walletPassBarcodePadding * 2,
            navigationBarButtonSide * 1.25
        )
        .rounded(.toNearestOrAwayFromZero)
    }
    /// 票面条码圆角。
    static var walletPassBarcodeCornerRadius: CGFloat { radiusPoster }
    /// 地点底栏 / 长条凭证码共用高度（文案块与 glass 圆钮取高，再加垂直 padding）。
    static func walletPassFooterBandHeight(navigationBarButtonSide: CGFloat) -> CGFloat {
        let label = UIFont.preferredFont(forTextStyle: .caption2).lineHeight
        let value = UIFont.preferredFont(forTextStyle: .footnote).lineHeight
        let textBlock = label + systemTextToSecondaryPadding + value
        let chrome = max(textBlock, navigationBarButtonSide)
        return chrome + formRowVerticalPadding * 2
    }
    /// 系统 Wallet 叠卡露条：后方只露 header（标题/人数 ↔ 时间/日期），由详情 Form 字阶推导。
    static var walletPassStackHeaderPeek: CGFloat {
        let title = UIFont.preferredFont(forTextStyle: .body).lineHeight
        let meta = UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
        let header = title + systemTextToSecondaryPadding + max(meta, title)
        return (formRowVerticalPadding + header + formRowVerticalPadding)
            .rounded(.toNearestOrAwayFromZero)
    }
    /// 「我的」预览堆：露条约等于系统 header 条。
    static var walletPassStackCollapsedPeek: CGFloat { walletPassStackHeaderPeek }
    /// 凭证夹扇出：略多于 header，便于辨认下一张。
    static var walletPassStackScrollingPeek: CGFloat {
        (walletPassStackHeaderPeek + g(1)).rounded(.toNearestOrAwayFromZero)
    }
    /// 堆叠额外高度上限：预览堆 4 张需 3 条露缝；再留 1 条余量避免压缩。
    static var walletPassStackMaxExtraHeight: CGFloat { walletPassStackHeaderPeek * 4 }

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusCard, style: .continuous)
    }

    static var walletPassFaceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusPoster, style: .continuous)
    }

    /// 长条凭证外形（与展开票面同圆角家族）。
    static var walletPassStripBarShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusPoster, style: .continuous)
    }

    static var walletPassBarcodeShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusMedia, style: .continuous)
    }

    static var posterShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusPoster, style: .continuous)
    }

    static var editorialShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusEditorial, style: .continuous)
    }

    static var fullBleedShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: 0, style: .continuous)
    }

    static var mediaShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusMedia, style: .continuous)
    }
}

/// Dynamic Type：无障碍字阶放开行数；常规字阶保持卡片密度
enum DiscoverAccessibility {
    static func titleLineLimit(for size: DynamicTypeSize) -> Int? {
        size.isAccessibilitySize ? nil : 2
    }

    static func metaLineLimit(for size: DynamicTypeSize) -> Int? {
        size.isAccessibilitySize ? 4 : 1
    }

    static func bodyLineLimit(for size: DynamicTypeSize, regular: Int = 2) -> Int? {
        size.isAccessibilitySize ? nil : regular
    }

    /// 无障碍字阶：封面叠字易裁切，改为图下信息区（HIG）
    static func prefersStackedCardChrome(for size: DynamicTypeSize) -> Bool {
        size.isAccessibilitySize
    }
}
