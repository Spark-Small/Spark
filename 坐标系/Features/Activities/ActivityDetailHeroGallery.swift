//
//  ActivityDetailHeroGallery.swift
//  坐标系
//
//  活动详情 Hero 相册：多图分页滑动；无点按 / 计数芯片全屏预览。
//

import SwiftUI
import CoordinateModels

// MARK: - Hero / 相册

struct ActivityDetailHeroGallery: View {
    let activity: Activity
    var onEditGallery: (() -> Void)?
    /// 发起预览：覆盖 store 中的配图文件名（不含封面）。
    var galleryExtraNames: [String]? = nil

    private var photos: [CommunityPhotoRef] {
        ActivityDetailContentStore.galleryPhotos(
            for: activity,
            galleryExtraNames: galleryExtraNames
        )
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            photoLayer
                .clipShape(PlatformMetrics.cardShape)
                .contentShape(PlatformMetrics.cardShape)
                .accessibilityLabel(ActivityDetailCopy.heroGalleryA11y)

            if let onEditGallery {
                Button(action: onEditGallery) {
                    Label("编辑相册", systemImage: "square.and.pencil")
                }
                .labelStyle(.titleAndIcon)
                .activityGlassChip()
                .platformMediaChromeInset()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var photoLayer: some View {
        if photos.count > 1 {
            TabView {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, ref in
                    CommunityRemotePhoto(ref: ref)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .accessibilityLabel(
                            ActivityDetailCopy.heroGalleryPageA11y(
                                index: index + 1,
                                total: photos.count
                            )
                        )
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .accessibilityElement(children: .contain)
            .accessibilityHint(ActivityDetailCopy.heroGallerySwipeHint)
        } else if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: activity.coverSeed, symbol: activity.coverSymbol))
        }
    }
}
