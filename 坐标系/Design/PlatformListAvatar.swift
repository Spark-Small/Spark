//
//  PlatformListAvatar.swift
//  坐标系
//
//  系统列表头像与 monogram 组件。
//

import SwiftUI
import UIKit

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
            if CommunityPhotoStore.isVideo(url: url) {
                return await CommunityPhotoStore.posterImage(for: url)
            }
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

    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    var body: some View {
        PlatformListAvatarView(
            name: name,
            photo: photo,
            photoRef: photoRef,
            side: chromeMeasurements.navigationBarButtonSide
        )
        .platformToolbarAvatarChrome()
    }
}

private struct PlatformToolbarAvatarChromeModifier: ViewModifier {
    @Environment(\.platformChromeMeasurements) private var chromeMeasurements

    func body(content: Content) -> some View {
        let side = chromeMeasurements.navigationBarButtonSide
        return content
            .frame(width: side, height: side)
            .clipShape(Circle())
            .platformToolbarAvatarRing()
            .mask(Circle())
            .contentShape(Circle())
    }
}

private extension View {
    /// 头像盘与 glass 外圈同径；mask 裁掉 material 外扩
    func platformToolbarAvatarChrome() -> some View {
        modifier(PlatformToolbarAvatarChromeModifier())
    }
}

// MARK: - Dynamic Type → 头像边长

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

    /// Apple 账号式资料头像 ≈ 列表头像 × 2.5（约 100pt @默认字号）
    var accountHeaderAvatarSide: CGFloat {
        (listAvatarSide * 2.5).rounded(.toNearestOrAwayFromZero)
    }

    /// 好友动态封面 ≈ 列表头像 × 1.6
    var friendPostCoverSide: CGFloat {
        (listAvatarSide * 1.6).rounded(.toNearestOrAwayFromZero)
    }

    /// 评论 Sheet 主楼头像 ≈ 列表 × 0.9（默认 ≈36pt）
    var commentThreadRootAvatarSide: CGFloat {
        (listAvatarSide * 0.9).rounded(.toNearestOrAwayFromZero)
    }

    /// 评论 Sheet 回复头像 ≈ 主楼 × 2/3（默认 ≈24pt）
    var commentThreadReplyAvatarSide: CGFloat {
        max(20, (commentThreadRootAvatarSide * (2.0 / 3.0)).rounded(.toNearestOrAwayFromZero))
    }

    /// 回复行左缩进 = 主楼头像 + subtitleCell 图↔文间距（与主楼正文列对齐）
    var commentThreadReplyLeadingInset: CGFloat {
        commentThreadRootAvatarSide + PlatformConversationListRow.imageToTextPadding
    }
}
