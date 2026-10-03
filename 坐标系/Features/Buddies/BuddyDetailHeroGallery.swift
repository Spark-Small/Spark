//
//  BuddyDetailHeroGallery.swift
//  坐标系
//
//  搭子详情 Hero / 相册：多图系统 TabView 分页（同发现卡）；无点按全屏预览。
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

/// 搭子详情头图相册：左右滑切换；不进全屏预览。
struct BuddyDetailPhotoGallery: View {
    let profile: BuddyProfile
    var verifiedBadge: Bool = false

    private var photos: [CommunityPhotoRef] { profile.photoRefs }

    var body: some View {
        coverMedia
            .overlay(alignment: .topLeading) {
                if verifiedBadge {
                    PlatformMediaCaptionBadge(title: BuddyDetailCopy.verifiedBadge, tint: .accentColor)
                        .platformMediaChromeInset()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var coverMedia: some View {
        let cover = HeroPersonCover(
            name: profile.nickname,
            photos: photos,
            allowsPaging: true
        )
        .clipShape(PlatformMetrics.cardShape)
        .contentShape(PlatformMetrics.cardShape)
        .accessibilityLabel(BuddyDetailCopy.photoA11y(profile.nickname))

        if photos.count > 1 {
            cover.accessibilityHint(BuddyDetailCopy.photoSwipeHint)
        } else {
            cover
        }
    }
}
