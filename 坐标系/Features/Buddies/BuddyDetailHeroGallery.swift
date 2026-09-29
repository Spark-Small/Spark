//
//  BuddyDetailHeroGallery.swift
//  坐标系
//
//  搭子详情 Hero / 相册。
//

import SwiftUI
import CoordinateModels

// MARK: - Hero

struct BuddyDetailHeroGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    private var showsDistanceChip: Bool { PrivacyPreferences.showDistance }

    private var distanceChipTitle: String {
        "\(BuddyDetailCopy.distanceChipPrefix) · \(profile.distanceText)"
    }

    var body: some View {
        DetailHeroChrome(showsChip: showsDistanceChip) {
            BuddyDetailPhotoGallery(profile: profile, verifiedBadge: verifiedBadge)
        } chip: { onMedia in
            DetailHeroInfoChip(
                title: distanceChipTitle,
                systemImage: "location.fill",
                onMedia: onMedia
            )
        }
    }
}

/// 搭子详情头图相册（对齐 `ActivityDetailHeroGallery`：仅封面 + 右下控件）。
struct BuddyDetailPhotoGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    @State private var preview: CommunityPhotoDestination?

    private var photos: [CommunityPhotoRef] { profile.photoRefs }

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
            .accessibilityLabel("\(profile.nickname)的照片")

            if photos.count > 1 {
                HStack {
                    Button {
                        openPreview(at: 0)
                    } label: {
                        Label(CommunityMediaCopy.countChip(photos), systemImage: "photo.on.rectangle.angled")
                    }
                    .labelStyle(.titleAndIcon)
                    .activityGlassChip()
                }
                .platformMediaChromeInset()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .topLeading) {
            if verifiedBadge {
                PlatformMediaCaptionBadge(title: BuddyDetailCopy.verifiedBadge, tint: .accentColor)
                    .platformMediaChromeInset()
            }
        }
        .communityPhotoCover($preview)
    }

    private func openPreview(at index: Int) {
        guard !photos.isEmpty else { return }
        preview = CommunityPhotoDestination(photos: photos, startIndex: index)
    }

    @ViewBuilder
    private var photoLayer: some View {
        if let first = photos.first {
            CommunityRemotePhoto(ref: first)
        } else {
            CommunityRemotePhoto(ref: .seeded(seed: abs(profile.id.hashValue % 9000) + 100, symbol: "person.fill"))
        }
    }
}

