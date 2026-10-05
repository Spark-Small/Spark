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
    /// 「我的」根照片墙分区（Ins / Facebook 式网格，不在个人资料 Form）。
    static let sectionTitle = "照片"
    static let emptyDetail = "还没有照片"
    static let emptyHint = "添加对外展示的生活照片"
    static let addAccessibility = "添加照片或视频"
    static let removeAccessibility = "删除照片"
    static func countAccessibility(_ count: Int) -> String {
        "照片与视频，共 \(count) 项"
    }
    static func itemAccessibility(index: Int) -> String {
        "照片 \(index)"
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

    private let columns = [
        GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
        GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
        GridItem(.flexible(), spacing: PlatformMetrics.minContentGap)
    ]

    var body: some View {
        let items = displayRefs
        if items.isEmpty {
            if let emptyTitle {
                Text(emptyTitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } else {
            LazyVGrid(columns: columns, spacing: PlatformMetrics.minContentGap) {
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
                Color.secondary.opacity(0.12)
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
