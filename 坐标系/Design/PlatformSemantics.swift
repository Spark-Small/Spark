//
//  PlatformSemantics.swift
//  坐标系
//
//  仅封装 Apple 平台语义 API（系统色 / Dynamic Type / 材质 / Glass），
//  不引入品牌色或自定义 HSB。
//

import SwiftUI
import UIKit

enum PlatformSurface {
    /// 发现类列表页（活动、搭子）
    static var groupedPage: Color { Color(.systemGroupedBackground) }
    /// 内容流页（社区、详情正文）
    static var canvas: Color { Color(.systemBackground) }
    /// 分组页上的卡片（活动列表卡、详情信息块）
    static var elevated: Color { Color(.secondarySystemGroupedBackground) }
    /// 白底详情页上的信息块（社区正文等 canvas 场景）
    static var groupedBlock: Color { Color(.secondarySystemBackground) }
    static var bar: Material { .bar }
    static var thin: Material { .thinMaterial }
}

/// 系统状态色 — SwiftUI 内置语义色，非品牌自定义
enum PlatformStatus {
    static var success: Color { .green }
    static var warning: Color { .orange }
    static var danger: Color { .red }
    static var accent: Color { .accentColor }
}

extension DynamicTypeSize {
    init(uiContentSizeCategory category: UIContentSizeCategory) {
        switch category {
        case .extraSmall: self = .xSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .xLarge
        case .extraExtraLarge: self = .xxLarge
        case .extraExtraExtraLarge: self = .xxxLarge
        case .accessibilityMedium: self = .accessibility1
        case .accessibilityLarge: self = .accessibility2
        case .accessibilityExtraLarge: self = .accessibility3
        case .accessibilityExtraExtraLarge: self = .accessibility4
        case .accessibilityExtraExtraExtraLarge: self = .accessibility5
        default: self = .large
        }
    }

    var uiContentSizeCategory: UIContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }

    /// 列表标准头像边长：与 `.body` 同 Dynamic Type 档位（默认 ≈40pt）
    var listAvatarSide: CGFloat {
        var bodyPointSize: CGFloat = 17
        UITraitCollection(preferredContentSizeCategory: uiContentSizeCategory).performAsCurrent {
            bodyPointSize = UIFont.preferredFont(forTextStyle: .body).pointSize
        }
        return max(30, (bodyPointSize * (40.0 / 17.0)).rounded(.toNearestOrAwayFromZero))
    }

    /// 横滑频道轨头像：列表 Dynamic Type 标准边长（通常 ≥ subtitleCell `imageSide`）
    var channelRailAvatarSide: CGFloat { listAvatarSide }

    /// 相关缩略图 ≈ 列表头像 × 1.85
    var detailRelatedThumbSide: CGFloat {
        (listAvatarSide * 1.85).rounded(.toNearestOrAwayFromZero)
    }

    /// 好友动态封面 ≈ 列表头像 × 1.6
    var friendPostCoverSide: CGFloat {
        (listAvatarSide * 1.6).rounded(.toNearestOrAwayFromZero)
    }
}

/// 系统列表头像：边长由 SwiftUI `DynamicTypeSize` 换算，SwiftUI 圆裁切绘制。
enum PlatformListAvatar {
    /// 指定 Dynamic Type 档下的列表标准头像边长（pt）
    static func standardPointSize(for dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        dynamicTypeSize.listAvatarSide
    }

    /// 无 SwiftUI Environment 时，由当前 UIKit trait 映射回 DynamicTypeSize
    static func standardPointSize() -> CGFloat {
        standardPointSize(for: DynamicTypeSize(
            uiContentSizeCategory: UITraitCollection.current.preferredContentSizeCategory
        ))
    }

    /// `.task(id:)` 键：同一 `photoRef` 不重复加载
    static func photoTaskID(_ ref: CommunityPhotoRef?, fallback: String) -> String {
        switch ref {
        case .remote(let url): "r:\(url.absoluteString)"
        case .file(let url): "f:\(url.absoluteString)"
        case .asset(let name): "a:\(name)"
        case .seeded(let seed, let symbol): "s:\(seed)-\(symbol)"
        case .none: "n:\(fallback)"
        }
    }

    /// 将照片收成列表头像位图（种子图由视图层 monogram 绘制；此处栅格化仅作兜底）
    @MainActor
    static func loadPhoto(_ ref: CommunityPhotoRef?, dynamicTypeSize: DynamicTypeSize) async -> UIImage? {
        guard let ref else { return nil }
        switch ref {
        case .remote(let url):
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return nil }
            return UIImage(data: data)
        case .file(let url):
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        case .asset(let name):
            return UIImage(named: name)
        case .seeded:
            return nil
        }
    }
}

/// SwiftUI 列表 monogram：系统色圆底 + 首字母（Contacts 示例写法）
struct PlatformListAvatarMonogram: View {
    let name: String

    private var initial: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let char = trimmed.prefix(1)
        return char.isEmpty ? "·" : String(char)
    }

    private var fill: Color {
        SeededPalette.primary(for: abs(name.hashValue))
    }

    var body: some View {
        Text(initial)
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(fill, in: Circle())
            .accessibilityHidden(true)
    }
}

/// 消息列表同规格 SF Symbol 头像（`.secondary` + `resizable`）。
struct PlatformListSymbolAvatar: View {
    var systemName: String
    var side: CGFloat? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var resolvedSide: CGFloat { side ?? dynamicTypeSize.listAvatarSide }

    var body: some View {
        Image(systemName: systemName)
            .resizable()
            .scaledToFit()
            .frame(width: resolvedSide, height: resolvedSide, alignment: .center)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

/// 系统 SF Symbol 圆头像（消息模块标准写法）。
struct PlatformSystemAvatar: View {
    var side: CGFloat? = nil

    var body: some View {
        PlatformListSymbolAvatar(systemName: "person.crop.circle.fill", side: side)
    }
}

/// 系统圆头像：内容铺满圆框；默认 `listAvatarSide`。
struct PlatformListAvatarView: View {
    var name: String
    var photo: UIImage? = nil
    var photoRef: CommunityPhotoRef? = nil
    var side: CGFloat? = nil

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var loadedPhoto: UIImage?

    private var resolvedSide: CGFloat { side ?? dynamicTypeSize.listAvatarSide }
    private var resolvedPhoto: UIImage? { photo ?? loadedPhoto }

    private var showsSilhouette: Bool {
        name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var usesSeededMonogram: Bool {
        guard photo == nil, let photoRef else { return false }
        if case .seeded = photoRef { return true }
        return false
    }

    var body: some View {
        ZStack {
            if let resolvedPhoto {
                Image(uiImage: resolvedPhoto)
                    .resizable()
                    .scaledToFill()
            } else if usesSeededMonogram || !showsSilhouette {
                PlatformListAvatarMonogram(name: name)
            } else {
                Color(.tertiarySystemFill)
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFill()
                    .foregroundStyle(.tertiary)
                    .padding(PlatformMetrics.formRowVerticalPadding)
            }
        }
        .frame(width: resolvedSide, height: resolvedSide)
        .clipShape(Circle())
        .accessibilityHidden(true)
        .task(id: avatarLoadTaskID) {
            guard photo == nil else {
                loadedPhoto = nil
                return
            }
            if usesSeededMonogram {
                loadedPhoto = nil
                return
            }
            loadedPhoto = await PlatformListAvatar.loadPhoto(photoRef, dynamicTypeSize: dynamicTypeSize)
        }
    }

    private var avatarLoadTaskID: String {
        "\(PlatformListAvatar.photoTaskID(photoRef, fallback: name))-\(dynamicTypeSize)-\(resolvedSide)"
    }
}

/// 资料编辑：同径铺满的圆形 glass 头像（单层 clip + glass + mask）。
struct PlatformToolbarAvatarLabel: View {
    var name: String
    var photo: UIImage? = nil
    var photoRef: CommunityPhotoRef? = nil

    var body: some View {
        PlatformListAvatarView(
            name: name,
            photo: photo,
            photoRef: photoRef,
            side: PlatformMetrics.navigationBarButtonSide
        )
        .platformToolbarAvatarChrome()
    }
}

private extension View {
    /// 头像盘与 glass 外圈同径；mask 裁掉 material 外扩
    func platformToolbarAvatarChrome() -> some View {
        let side = PlatformMetrics.navigationBarButtonSide
        return self
            .frame(width: side, height: side)
            .clipShape(Circle())
            .glassEffect(.regular.interactive(), in: .circle)
            .mask(Circle())
            .contentShape(Circle())
    }
}

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

    private static var cachedTableHorizontalInset: [String: CGFloat] = [:]

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

    private static func resolvedKeyViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        guard let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first
        else { return nil }

        var controller: UIViewController? = window.rootViewController
        while let presented = controller?.presentedViewController {
            controller = presented
        }
        if let nav = controller as? UINavigationController {
            controller = nav.visibleViewController ?? nav
        }
        if let tab = controller as? UITabBarController {
            controller = tab.selectedViewController ?? tab
            if let nav = controller as? UINavigationController {
                controller = nav.visibleViewController ?? nav
            }
        }
        return controller
    }

    /// 顶栏 / `.searchable` drawer 的水平页边（与收件箱搜索框对齐）
    private static func resolvedNavigationHorizontalInset() -> CGFloat {
        guard let controller = resolvedKeyViewController() else { return 0 }
        if let nav = controller.navigationController ?? controller as? UINavigationController {
            nav.navigationBar.layoutIfNeeded()
            let barLeading = max(
                nav.navigationBar.directionalLayoutMargins.leading,
                nav.navigationBar.layoutMargins.left
            )
            if barLeading > 0 { return barLeading }
        }
        let viewLeading = max(
            controller.view.directionalLayoutMargins.leading,
            controller.view.layoutMargins.left
        )
        return viewLeading > 0 ? viewLeading : 0
    }

    private static func systemMinimumHorizontalMargin() -> CGFloat {
        guard let controller = resolvedKeyViewController() else { return 0 }
        return controller.systemMinimumLayoutMargins.leading
    }

    private static func keyWindowWidth() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let window = scenes.flatMap(\.windows).first(where: \.isKeyWindow)
            ?? scenes.first?.windows.first {
            return window.bounds.width
        }
        return 390
    }

    private static var systemListVertical: CGFloat {
        let top = UIListContentConfiguration.subtitleCell().directionalLayoutMargins.top
        if top > 0 { return top }
        return UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    /// 系统 List 分节顶距（`UITableView.sectionHeaderTopPadding`）
    private static var cachedSectionHeaderTopPadding: [String: CGFloat] = [:]

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
    /// 封面角标边距 ≈ 列表行距
    static var captionBadgeInset: CGFloat { g(1.5) }
    /// 发现页滚动顶边（问候头）
    static var pageTopInset: CGFloat { g(0.5) }

    // MARK: - Rhythm（分区间距取系统 List 量，不用自定义 g 倍数）

    /// 发现大分区间距 = 系统 `sectionHeaderTopPadding`
    static var sectionSpacing: CGFloat { resolvedTableSectionHeaderTopPadding() }
    /// 分区标题 ↔ 内容 = 系统列表行垂直 margin
    static var sectionHeaderSpacing: CGFloat { systemListVertical }
    static var discoverCardSpacing: CGFloat { g(1.75) }
    static var railCardSpacing: CGFloat { g(1.5) }
    static var stackedMediaSpacing: CGFloat { g(1) }
    static var cardFooterSpacing: CGFloat { g(1.5) }
    static var emptyStateVerticalPadding: CGFloat { g(6) }
    static var captionBadgePaddingHorizontal: CGFloat { max(4, (caption2 * 0.55).rounded()) }
    static var captionBadgePaddingVertical: CGFloat { max(2, (caption2 * 0.25).rounded()) }
    /// 标题 ↔ 副标题 = 系统 subtitle 主副文间距
    static var sectionSubtitleSpacing: CGFloat { systemTextToSecondaryPadding }
    static var heroStackedTextInset: CGFloat { g(0.5) }
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
    static var composeCoverHeight: CGFloat { g(20) }
    static var hairlineSpacing: CGFloat { max(2, g(0.25)) }
    static var formRowVerticalPadding: CGFloat {
        max(2, (systemListVertical * 0.35).rounded(.toNearestOrAwayFromZero))
    }
    static var minContentGap: CGFloat { g(1) }
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

    /// 标准导航栏圆形按钮边长（消息头像与之对齐）
    static var navigationBarButtonSide: CGFloat { resolvedNavigationBarButtonSide() }

    private static var cachedNavigationBarButtonSide: [String: CGFloat] = [:]

    /// 系统导航栏按钮边长：优先 `UIButton.Configuration.glass`（与 iOS 26 顶栏圆形 glass 同档），
    /// 再回退到 `UINavigationBar` 上 `UIBarButtonItem` 控件实测。
    private static func resolvedNavigationBarButtonSide(
        for category: UIContentSizeCategory = UITraitCollection.current.preferredContentSizeCategory
    ) -> CGFloat {
        let key = category.rawValue
        if let cached = cachedNavigationBarButtonSide[key] { return cached }

        var resolved: CGFloat = 0
        UITraitCollection(preferredContentSizeCategory: category).performAsCurrent {
            // 顶栏圆形 glass：与 SwiftUI ToolbarItem 系统按钮同族（medium）
            var configuration = UIButton.Configuration.glass()
            configuration.buttonSize = .medium
            configuration.image = UIImage(systemName: "person.crop.circle")
            configuration.cornerStyle = .capsule
            configuration.setDefaultContentInsets()
            let glassButton = UIButton(configuration: configuration)
            glassButton.sizeToFit()
            var glassSide = glassButton.bounds.height
            if glassSide <= 0 {
                glassSide = glassButton.systemLayoutSizeFitting(
                    CGSize(width: UIView.layoutFittingCompressedSize.width, height: 0),
                    withHorizontalFittingPriority: .fittingSizeLevel,
                    verticalFittingPriority: .fittingSizeLevel
                ).height
            }
            if glassSide <= 0 {
                glassSide = glassButton.intrinsicContentSize.height
            }

            // 对照：真实 UINavigationBar 上的 bar button 控件
            let host = UIViewController()
            let navigation = UINavigationController(rootViewController: host)
            host.navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: UIImage(systemName: "ellipsis"),
                style: .plain,
                target: nil,
                action: nil
            )
            let width = max(Self.keyWindowWidth(), 320)
            navigation.view.frame = CGRect(x: 0, y: 0, width: width, height: 200)
            navigation.view.setNeedsLayout()
            navigation.view.layoutIfNeeded()

            var barSide: CGFloat = 0
            if let control = Self.findNavigationBarButtonControl(in: navigation.navigationBar) {
                barSide = max(control.bounds.width, control.bounds.height)
            }

            // 取较大者：避免只量到符号字号而小于可见 glass 圆
            resolved = max(glassSide, barSide)

            if resolved <= 0 {
                let configuration = UIImage.SymbolConfiguration(textStyle: .body, scale: .large)
                if let image = UIImage(systemName: "circle.fill", withConfiguration: configuration) {
                    resolved = max(image.size.width, image.size.height)
                }
            }

            if resolved <= 0 {
                resolved = max(36, (bodyPointSize * (40.0 / 17.0)).rounded(.toNearestOrAwayFromZero))
            }
        }

        cachedNavigationBarButtonSide[key] = resolved
        return resolved
    }

    private static func findNavigationBarButtonControl(in view: UIView) -> UIControl? {
        if let control = view as? UIControl, control.bounds.width > 0, control.bounds.height > 0 {
            return control
        }
        for subview in view.subviews {
            if let found = findNavigationBarButtonControl(in: subview) {
                return found
            }
        }
        return nil
    }

    /// 信息输入栏：间距取系统 List 量；单行胶囊高度对齐同屏 SwiftUI `.glass` + `.large`「+」（UIButton 探测仅作首帧回退）
    static var composerToolSpacing: CGFloat { systemImageToTextPadding }
    static var composerFieldHorizontalPadding: CGFloat { systemImageToTextPadding }
    /// 多行时胶囊垂直内边距 = large glass contentInsets
    static var composerFieldVerticalPadding: CGFloat { resolvedLargeGlassContentInsets().top }
    /// 首帧回退高度（Preference 读到真实「+」后以实测为准）
    static var composerToolHeightFallback: CGFloat { resolvedLargeGlassHeight() }
    static var composerBarVerticalPadding: CGFloat { systemTextToSecondaryPadding }
    static var composerInlineSpacing: CGFloat { systemTextToSecondaryPadding }

    private static var cachedLargeGlassHeight: CGFloat?
    private static var cachedLargeGlassInsets: NSDirectionalEdgeInsets?

    private static func resolvedLargeGlassConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.glass()
        configuration.buttonSize = .large
        configuration.image = UIImage(systemName: "plus")
        configuration.cornerStyle = .capsule
        configuration.setDefaultContentInsets()
        return configuration
    }

    private static func resolvedLargeGlassHeight() -> CGFloat {
        if let cachedLargeGlassHeight { return cachedLargeGlassHeight }
        let button = UIButton(configuration: resolvedLargeGlassConfiguration())
        button.sizeToFit()
        var height = button.bounds.height
        if height <= 0 {
            height = button.systemLayoutSizeFitting(
                CGSize(width: UIView.layoutFittingCompressedSize.width, height: 0),
                withHorizontalFittingPriority: .fittingSizeLevel,
                verticalFittingPriority: .fittingSizeLevel
            ).height
        }
        if height <= 0 {
            height = button.intrinsicContentSize.height
        }
        let resolved = height > 0 ? height : (bodyPointSize * 2.4).rounded(.toNearestOrAwayFromZero)
        cachedLargeGlassHeight = resolved
        return resolved
    }

    private static func resolvedLargeGlassContentInsets() -> NSDirectionalEdgeInsets {
        if let cachedLargeGlassInsets { return cachedLargeGlassInsets }
        let insets = resolvedLargeGlassConfiguration().contentInsets
        cachedLargeGlassInsets = insets
        return insets
    }

    // MARK: - Radii（continuous，由 grid 推导）

    static var radiusMedia: CGFloat { g(1.5) }
    static var radiusCard: CGFloat { g(2.5) }
    static var detailBlockSpacing: CGFloat { discoverCardSpacing }
    /// 卡宽高比为构图比，非 pt
    static var activityCardAspectRatio: CGFloat { 16 / 9 }
    static var continueCardAspectRatio: CGFloat { 16 / 9 }
    /// 榜单 / 组织 / 语音厅竖海报（宽:高）；略扁于经典 2:3，降低货架轨高
    static var posterCardAspectRatio: CGFloat { 3 / 4 }
    static var featuredCardAspectRatio: CGFloat { 3 / 4 }
    static var editorialCardAspectRatio: CGFloat { 4 / 5 }
    /// 搭子人像竖卡（宽:高）— 详情 Hero / 旧舞台
    static var personCardAspectRatio: CGFloat { 9 / 16 }
    /// 搭子发现网格竖卡（宽:高）；短于舞台，一屏约 4～6 人
    static var personGridCardAspectRatio: CGFloat { 3 / 4 }
    /// 同好 / 陪玩发现网格列数
    static var personGridColumnCount: Int { 2 }
    static var radiusEditorial: CGFloat { g(3) }
    static var radiusPoster: CGFloat { g(1.75) }
    /// 轨可见比例为构图分数，非 pt
    static var editorialRailVisibleFraction: CGFloat { 0.88 }
    /// 海报轨卡宽占比：约两张半 + 露边；配合 3:4 控制轨高
    static var posterRailVisibleFraction: CGFloat { 0.36 }
    /// 背景大图轻微放大（切换时）
    static var personStageBackgroundScale: CGFloat { 1.06 }
    /// 舞台外框与精选 Hero 同比例（3:4）
    static var personStageAspectRatio: CGFloat { featuredCardAspectRatio }
    static var cardInfoSpacing: CGFloat { g(0.75) }
    static var metaSymbolSpacing: CGFloat { g(0.75) }
    /// 分区标题簇水平间距 = 系统图文间距
    static var sectionTitleClusterSpacing: CGFloat { systemImageToTextPadding }
    /// chevron 与标题间距 = 系统主副文间距
    static var sectionChevronSpacing: CGFloat { systemTextToSecondaryPadding }
    static var seeAllRankColumnWidth: CGFloat { g(4.5) }
    static var continueRailVisibleFraction: CGFloat { 0.86 }
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

    static var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: radiusCard, style: .continuous)
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

/// 系统短暂反馈：触觉 + VoiceOver 播报（不用自定义浮层 toast）
enum PlatformFeedback {
    @MainActor
    static func announce(_ message: String) {
        AccessibilityNotification.Announcement(message).post()
    }
}

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
    /// Photos 两侧圆形 glass（与中间胶囊同 controlSize → 同高）
    func platformToolbarCircleStyle() -> some View {
        self
            .buttonStyle(.glass)
            .buttonBorderShape(.circle)
            .controlSize(PlatformToolbarChrome.controlSize)
    }

    /// Photos 中间双行胶囊
    func platformToolbarPrincipalCapsuleStyle() -> some View {
        self
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(PlatformToolbarChrome.controlSize)
    }

    /// 处理中遮罩：Metrics 只在 Design 消费
    func platformProcessingOverlayChrome() -> some View {
        self
            .padding(PlatformMetrics.processingOverlayPadding)
            .background(.ultraThinMaterial, in: PlatformMetrics.processingOverlayShape)
    }

    /// 详情底栏悬浮 CTA 水平边距（Features 不手写 token）
    func activityDetailBottomBarChrome() -> some View {
        self.padding(.horizontal, PlatformMetrics.contentInset)
    }

    /// 媒体角上控件 inset（头图 chip / 相册编辑钮）
    func platformMediaChromeInset() -> some View {
        self.padding(PlatformMetrics.contentInset)
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

/// 行程等「卡入 List」行边距：几何收在 Design，Features 只调此 API
enum PlatformCardListRow {
    static var insets: EdgeInsets {
        EdgeInsets(
            top: PlatformMetrics.sectionHeaderSpacing,
            leading: PlatformMetrics.contentInset,
            bottom: PlatformMetrics.sectionHeaderSpacing,
            trailing: PlatformMetrics.contentInset
        )
    }
}

/// 消息 List 行几何：默认值直接取自 Apple `UIListContentConfiguration.subtitleCell()`（及 plain `UITableView` 探针）。
enum PlatformConversationListRow {
    private static var configuration: UIListContentConfiguration {
        UIListContentConfiguration.subtitleCell()
    }

    /// 水平页边 = subtitleCell leading ∩ 表/导航栏 layout margins（`PlatformMetrics.contentInset`）
    static var horizontalInset: CGFloat { PlatformMetrics.contentInset }

    /// 行垂直 inset = subtitleCell 上下 layout margin
    static var verticalInset: CGFloat {
        let margins = configuration.directionalLayoutMargins
        let systemVertical = max(margins.top, margins.bottom)
        return systemVertical > 0
            ? systemVertical
            : UIFont.preferredFont(forTextStyle: .body).lineHeight
    }

    /// 垂直密度；水平由 `platformConversationListChrome` 的 contentMargins 提供
    static var insets: EdgeInsets {
        let vertical = verticalInset
        return EdgeInsets(top: vertical, leading: 0, bottom: vertical, trailing: 0)
    }

    /// 字母分节头垂直 = subtitleCell 上下 layout margin
    static var sectionHeaderInsets: EdgeInsets {
        EdgeInsets(top: verticalInset, leading: 0, bottom: verticalInset, trailing: 0)
    }

    /// List 分节间距 = 系统 `UITableView.sectionHeaderTopPadding`
    static var listSectionSpacing: CGFloat { PlatformMetrics.sectionSpacing }

    /// 图↔文 = `subtitleCell.imageToTextPadding`
    static var imageToTextPadding: CGFloat {
        let padding = configuration.imageToTextPadding
        return padding > 0 ? padding : PlatformMetrics.minContentGap
    }

    /// 主↔副文 = `subtitleCell.textToSecondaryTextVerticalPadding`
    static var textToSecondarySpacing: CGFloat {
        let padding = configuration.textToSecondaryTextVerticalPadding
        return padding > 0 ? padding : PlatformMetrics.sectionSubtitleSpacing
    }

    /// 含头像行 ↔ 下方独立内容块（配图等）= subtitleCell 行垂直 margin
    static var rowToContentSpacing: CGFloat { verticalInset }

    /// 列表头像边长 = `ImageProperties.standardDimension`
    static var imageSide: CGFloat {
        let side = UIListContentConfiguration.ImageProperties.standardDimension
        return side > 0 ? side : PlatformListAvatar.standardPointSize()
    }
}

extension View {
    /// 二级页：隐藏底部 TabBar（一级 Tab 根页不要用）
    func platformSecondaryPage() -> some View {
        toolbar(.hidden, for: .tabBar)
    }

    /// 有导航栈时：非根页隐藏 TabBar
    func platformTabBarHiddenWhenPushed(_ isRoot: Bool) -> some View {
        toolbar(isRoot ? .automatic : .hidden, for: .tabBar)
    }

    /// 消息模块：隐藏 List / Form 行与分节分隔线
    func platformMessagesSeparatorsHidden() -> some View {
        self
            .listRowSeparator(.hidden)
            .listSectionSeparator(.hidden)
    }

    /// 消息 / 好友共用 List 容器：plain + Apple subtitleCell 测得的水平页边与分节距
    func platformConversationListChrome() -> some View {
        self
            .listStyle(.plain)
            .platformMessagesSeparatorsHidden()
            .listSectionSpacing(PlatformConversationListRow.listSectionSpacing)
            .contentMargins(.horizontal, PlatformConversationListRow.horizontalInset, for: .scrollContent)
            .environment(\.defaultMinListRowHeight, 0)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(PlatformSurface.canvas)
    }

    /// 消息页级水平边距（ScrollView / 线程）
    func platformMessagePageMargins() -> some View {
        contentMargins(.horizontal, PlatformConversationListRow.horizontalInset, for: .scrollContent)
    }

    func platformMessagePagePadding() -> some View {
        padding(.horizontal, PlatformConversationListRow.horizontalInset)
    }

    /// 行垂直密度 = subtitleCell layout margins；放在 swipeActions 之后。水平页边见 `platformConversationListChrome()`。
    func platformConversationListRowChrome() -> some View {
        self
            .listRowInsets(PlatformConversationListRow.insets)
            .platformMessagesSeparatorsHidden()
    }

    /// 好友字母分节头垂直密度
    func platformConversationSectionHeaderChrome() -> some View {
        self
            .listRowInsets(PlatformConversationListRow.sectionHeaderInsets)
            .platformMessagesSeparatorsHidden()
    }
}

/// 消息二级页分区头：与好友列表字母分节头同密度
struct PlatformMessagesSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .platformConversationSectionHeaderChrome()
    }
}

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
                .symbolRenderingMode(.hierarchical)
        }
    }
}

extension View {
    /// 绑定短暂反馈文案：成功触觉 + 系统播报，无自定义浮层
    func platformTransientFeedback(_ message: Binding<String?>) -> some View {
        self
            .sensoryFeedback(.success, trigger: message.wrappedValue) { _, newValue in
                newValue != nil
            }
            .onChange(of: message.wrappedValue) { _, newValue in
                guard let newValue else { return }
                PlatformFeedback.announce(newValue)
            }
    }

    /// 静态标签：材质胶囊，规格与角标一致（系统 caption2）
    func platformGlassTag() -> some View {
        self
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
            .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
            .background(PlatformSurface.thin, in: Capsule())
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
    func activityPrimaryCTA(controlSize: ControlSize = .large) -> some View {
        self
            .buttonStyle(.glassProminent)
            .controlSize(controlSize)
            .buttonBorderShape(.capsule)
    }

    /// 次要 CTA 胶囊 — glass 次要态，与主 CTA 同家族
    func activitySecondaryCTA(controlSize: ControlSize = .large) -> some View {
        self
            .buttonStyle(.glass)
            .controlSize(controlSize)
            .buttonBorderShape(.capsule)
    }

    /// 圆形 glass 图标（关闭、日历、导航、私信、发送）
    @ViewBuilder
    func activityGlassIcon(prominent: Bool = false) -> some View {
        if prominent {
            self
                .buttonStyle(.glassProminent)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        } else {
            self
                .buttonStyle(.glass)
                .buttonBorderShape(.circle)
                .controlSize(.large)
        }
    }

    /// 头图小胶囊 glass（相册张数 / 编辑等紧凑控件）
    func activityGlassChip() -> some View {
        self
            .buttonStyle(.glass)
            .controlSize(.small)
            .buttonBorderShape(.capsule)
    }

    /// 信息 / 次要 glass 胶囊 — 用 `controlSize` 调档（`.regular` 对齐筛选条，`.large` 对齐底栏 CTA）
    func activityGlassCapsule(controlSize: ControlSize = .regular) -> some View {
        self
            .buttonStyle(.glass)
            .controlSize(controlSize)
            .buttonBorderShape(.capsule)
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

private extension View {
    @ViewBuilder
    func platformMaterialTagChrome(isSelected: Bool) -> some View {
        if isSelected {
            self
                .background(PlatformSurface.bar, in: Capsule())
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
            Capsule().fill(.thinMaterial)
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
