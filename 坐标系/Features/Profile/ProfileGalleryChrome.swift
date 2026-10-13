//
//  ProfileGalleryChrome.swift
//  坐标系
//
//  个人资料照片墙：只读网格（详情）+ 编辑添加占位（PhotosPicker label）。
//

import CoordinateModels
import SwiftUI
import UIKit

enum ProfileGalleryCopy {
    /// 对外只读照片墙文案（好友/作者资料等）。
    static let sectionTitle = "照片"
    static let emptyDetail = "还没有照片"
    static let emptyHint = "暂无可展示的照片"
    static let addAccessibility = "添加照片或视频"
    static let removeAccessibility = "删除照片"
    static func countAccessibility(_ count: Int) -> String {
        "照片与视频，共 \(count) 项"
    }
    static func itemAccessibility(index: Int) -> String {
        "照片 \(index)"
    }
    static let openPhotoHint = "打开大图"
    static let swipeHint = "左右滑动切换照片"
    /// 大图导航标题：`2/5`。
    static func pagerTitle(index: Int, total: Int) -> String {
        "\(index)/\(total)"
    }
}

/// 详情页只读照片墙（本机文件名或 `CommunityPhotoRef`）。
struct ProfileGalleryReadonlyGrid: View {
    var localNames: [String] = []
    var refs: [CommunityPhotoRef] = []
    var emptyTitle: String? = ProfileGalleryCopy.emptyDetail

    private var displayRefs: [CommunityPhotoRef] {
        if !refs.isEmpty { return refs }
        return localNames.compactMap { name in
            LocalMediaLibrary.fileURL(named: name).map(CommunityPhotoRef.file)
        }
    }

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: PlatformMetrics.profilePhotoGridSpacing),
        count: 3
    )

    var body: some View {
        let items = displayRefs
        if items.isEmpty {
            if let emptyTitle {
                Text(emptyTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            LazyVGrid(columns: columns, spacing: PlatformMetrics.profilePhotoGridSpacing) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, ref in
                    CommunityRemotePhoto(ref: ref)
                        .frame(minHeight: PlatformMetrics.galleryEditorThumb)
                        .aspectRatio(1, contentMode: .fit)
                        .clipShape(PlatformMetrics.mediaShape)
                        .accessibilityHidden(true)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(ProfileGalleryCopy.countAccessibility(items.count))
        }
    }
}

struct ProfileGalleryThumb: View {
    let localName: String
    /// `false`：Ins 式方格直角裁切；`true`：圆角媒体皮（问答/详情缩略）。
    var usesMediaShape = true
    @State private var image: UIImage?
    @State private var isVideo = false

    var body: some View {
        Group {
            if usesMediaShape {
                thumbFill.clipShape(PlatformMetrics.mediaShape)
            } else {
                thumbFill.clipShape(Rectangle())
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
        .task(id: localName) {
            await load()
        }
    }

    private var thumbFill: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                PlatformSurface.tertiaryFill
            }
            if isVideo {
                Image(systemName: "play.circle.fill")
                    .font(PlatformListTypography.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
        }
    }

    @MainActor
    private func load() async {
        guard let url = LocalMediaLibrary.fileURL(named: localName) else {
            image = nil
            isVideo = false
            return
        }
        isVideo = LocalMediaLibrary.isVideo(url: url)
        if isVideo {
            image = await LocalMediaLibrary.posterImage(for: url)
        } else {
            image = await PlatformLocalImageCache.loadAsync(atPath: url.path)
        }
    }
}
