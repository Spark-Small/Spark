//
//  ActivityDetailHeroGallery.swift
//  坐标系
//
//  活动详情 Hero 相册。
//

import SwiftUI
import CoordinateModels

// MARK: - Hero / 相册

struct ActivityDetailHeroGallery: View {
    let activity: Activity
    var onEditGallery: (() -> Void)?

    @State private var preview: CommunityPhotoDestination?

    private var photos: [CommunityPhotoRef] {
        ActivityDetailContentStore.galleryPhotos(for: activity)
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Button {
                openPreview(at: 0)
            } label: {
                photoLayer
                    .clipShape(PlatformMetrics.cardShape)
                    .contentShape(PlatformMetrics.cardShape)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("查看活动相册")

            // 控件单独一层，避免被头图点击抢走
            HStack() {
                if photos.count > 1 {
                    Button {
                        openPreview(at: 0)
                    } label: {
                        Label(CommunityMediaCopy.countChip(photos), systemImage: "photo.on.rectangle.angled")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }

                if let onEditGallery {
                    Button(action: onEditGallery) {
                        Label("编辑相册", systemImage: "square.and.pencil")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }
            }
            .platformMediaChromeInset()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .communityPhotoCover($preview)
    }

    private func openPreview(at index: Int) {
        guard !photos.isEmpty else { return }
        preview = CommunityPhotoDestination(photos: photos, startIndex: index)
    }

    /// 与发现卡同源单帧封面；多图进全屏查看器翻页
    @ViewBuilder
    private var photoLayer: some View {
        if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: activity.coverSeed, symbol: activity.coverSymbol))
        }
    }
}

