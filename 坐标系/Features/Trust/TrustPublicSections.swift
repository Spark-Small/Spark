//
//  TrustPublicSections.swift
//  坐标系
//
//  信任档案：等级 + 形象认证 + 履约徽章 + 近 90 天事实（单一 Form Section）。
//

import CoordinateModels
import SwiftUI

struct TrustPublicProfileSections: View {
    let nickname: String
    var currentUserName: String
    var buddyItem: DiscoverBuddyItem?
    var liveHostedCount: Int = 0
    /// Sheet / 作者页用紧凑；好友 / 搭子详情用完整。
    var compact: Bool = false

    @Environment(AppModel.self) private var app
    @Environment(MembershipStore.self) private var membership
    @Environment(TrustService.self) private var trust
    @Environment(ProductLifecycleStore.self) private var lifecycle
    @Environment(PhotoVerificationStore.self) private var photoVerification

    private var isSelf: Bool {
        nickname.caseInsensitiveCompare(currentUserName) == .orderedSame
    }

    private var credentials: TrustPublicCredentials.Flags {
        _ = photoVerification.isVerified
        return TrustPublicCredentials.flags(
            nickname: nickname,
            currentUserName: currentUserName,
            buddyItem: buddyItem,
            membershipActive: membership.isEntitled,
            liveHostedCount: liveHostedCount,
            verificationPhotos: isSelf ? app.user.verificationPhotos : []
        )
    }

    private var card: TrustPublicCard {
        _ = trust.revision
        let flags = credentials
        return trust.publicCard(
            for: nickname,
            currentUserName: currentUserName,
            buddyItem: buddyItem,
            signals: TrustPrivateSignals(
                profileRatio: isSelf ? ProfileCompletion.ratio(for: app.user) : 0.5,
                isMember: flags.isMember,
                isGuest: isSelf && app.auth.isGuest,
                hasPhone: isSelf && !app.auth.isGuest && !app.auth.phoneNumber.isEmpty,
                photoVerified: flags.photoVerified,
                accountCreatedAt: isSelf ? lifecycle.installAt : nil,
                friendCount: 0,
                liveHostedCount: liveHostedCount
            )
        )
    }

    var body: some View {
        let data = card
        let flags = credentials
        let extraBadges = earnedTrustBadges(from: data.badges)

        Section {
            TrustLevelStrip(level: data.level)

            if flags.photoVerified {
                Label(
                    TrustBadgeKind.photoVerified.title,
                    systemImage: TrustBadgeKind.photoVerified.systemImage
                )
                .symbolRenderingMode(.multicolor)
                .platformContentSymbolStyle()
            } else if isSelf {
                Label(
                    "形象认证未点亮",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .foregroundStyle(.secondary)
                .platformContentSymbolStyle()
            }

            if isSelf {
                publicVerificationPhotosRow
            }

            if !extraBadges.isEmpty {
                TrustBadgeRow(badges: extraBadges)
            } else if !isSelf, !flags.photoVerified {
                Text("认证徽章将随形象认证点亮。")
                    .foregroundStyle(.secondary)
            }

            TrustFactLabeledRows(
                facts: data.facts,
                responseHint: data.responseHint
            )
        } header: {
            Text(BuddyDetailCopy.trustArchiveTitle)
        } footer: {
            if compact {
                EmptyView()
            } else {
                Text("会员标识不在信任档案中展示；履约事实来自近 90 天行为记录。")
            }
        }
    }

    /// 信任档案内：不含形象认证（单独展示）与会员徽章
    private func earnedTrustBadges(from badges: [TrustBadge]) -> [TrustBadge] {
        badges.filter {
            $0.kind != .photoVerified && $0.kind != .activeMember
        }
    }

    @ViewBuilder
    private var publicVerificationPhotosRow: some View {
        let images = app.user.localPublicVerificationImages()
        if images.isEmpty {
            Text("认证照未对外展示")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                    ForEach(Array(images.enumerated()), id: \.offset) { _, image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 72, height: 72)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
            }
            .accessibilityLabel("对外展示的认证照，共 \(images.count) 张")
        }
    }
}

struct TrustPublicPreviewView: View {
    let nickname: String
    var buddyItem: DiscoverBuddyItem?

    @Environment(AppModel.self) private var app

    var body: some View {
        Form {
            TrustPublicProfileSections(
                nickname: nickname,
                currentUserName: app.user.name,
                buddyItem: buddyItem,
                compact: false
            )
        }
        .navigationTitle(BuddyDetailCopy.trustArchiveTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
