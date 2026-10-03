//
//  PlatformCatalogCardChrome.swift
//  坐标系
//
//  活动目录卡共用：封面定框、底栏信息行、轨宽 helper。
//

import SwiftUI
import CoordinateModels

enum PlatformCatalogCardChrome {
    static var shape: RoundedRectangle { PlatformMetrics.cardShape }
    static var infoSpacing: CGFloat { PlatformMetrics.cardInfoSpacing }
}

/// 定框封面（信息栏 Material 由外层 `platformMediaInfoBarChrome(_:)` 按角色提供）。
struct PlatformCatalogCoverFill: View {
    var photo: CommunityPhotoRef?
    var aspectRatio: CGFloat

    var body: some View {
        Color.clear
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay {
                CommunityRemotePhoto(ref: photo)
            }
            .clipped()
    }
}

/// 目录卡底栏：左信息 / 右「参加」；叠字时外层加 `platformMediaInfoBarChrome(.standard|.hero|…)`。
struct PlatformCatalogHeroFooter: View {
    let title: String
    let timeLine: String
    let metaLine: String
    var isJoined = false
    var isWaitlisted = false
    var isFull = false
    var onJoin: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
            VStack(alignment: .leading, spacing: PlatformCatalogCardChrome.infoSpacing) {
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                Text(secondaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .allowsHitTesting(false)
            .accessibilityHidden(true)

            ActivityPrimaryAction(
                isJoined: isJoined,
                isWaitlisted: isWaitlisted,
                isFull: isFull,
                controlSize: .regular,
                onJoin: onJoin
            )
        }
    }

    private var secondaryLine: String {
        if metaLine.isEmpty { return timeLine }
        if timeLine.isEmpty { return metaLine }
        return "\(timeLine) · \(metaLine)"
    }
}

extension View {
    /// 跟进 / 热场横卡轨：页边内一屏 1 卡全宽。
    func platformContinueRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.discoverRailFullWidthColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 焦点大卡轨：页边内一屏 1 卡全宽。
    func platformEditorialRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.discoverRailFullWidthColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 搭子精选 / 陪玩大卡竖轨：页边内一屏 2 卡。
    func platformPersonFeaturedRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.posterRailColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 榜单海报轨：页边内一屏 2 卡。
    func platformPosterRailFrame() -> some View {
        containerRelativeFrame(
            .horizontal,
            count: PlatformMetrics.posterRailColumnCount,
            span: 1,
            spacing: PlatformMetrics.railCardSpacing
        )
    }

    /// 「我的」Wallet 票面轨。
    func platformProfileWalletPassRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.profileLibraryRailVisibleFraction
        }
    }

    /// 个人内容库竖海报轨。
    func platformProfileLibraryRailFrame() -> some View {
        containerRelativeFrame(.horizontal) { length, _ in
            length * PlatformMetrics.profileLibraryRailVisibleFraction
        }
    }
}
