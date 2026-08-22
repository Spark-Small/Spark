//
//  TrustPublicSections.swift
//  坐标系
//
//  信任档案：等级 + 形象认证 + 履约徽章 + 近 90 天事实（单一 Form Section）。
//

import SwiftUI

struct TrustPublicProfileSections: View {
    let nickname: String
    var currentUserName: String
    var buddyItem: DiscoverBuddyItem?
    var liveHostedCount: Int = 0
    /// Sheet / 作者页用紧凑；好友 / 搭子详情用完整。
    var compact: Bool = false

    @Environment(AppModel.self) private var app
    @AppStorage("profile.membership.active") private var membershipActive = false

    private var isSelf: Bool {
        nickname.caseInsensitiveCompare(currentUserName) == .orderedSame
    }

    private var credentials: TrustPublicCredentials.Flags {
        _ = PhotoVerificationStore.shared.isVerified
        return TrustPublicCredentials.flags(
            nickname: nickname,
            currentUserName: currentUserName,
            buddyItem: buddyItem,
            membershipActive: membershipActive,
            liveHostedCount: liveHostedCount
        )
    }

    private var card: TrustPublicCard {
        _ = TrustService.shared.revision
        let flags = credentials
        return TrustService.shared.publicCard(
            for: nickname,
            currentUserName: currentUserName,
            buddyItem: buddyItem,
            signals: TrustPrivateSignals(
                profileRatio: isSelf ? ProfileCompletion.ratio(for: app.user) : 0.5,
                isMember: flags.isMember,
                isGuest: isSelf && app.auth.isGuest,
                hasPhone: isSelf && !app.auth.isGuest && !app.auth.phoneNumber.isEmpty,
                photoVerified: flags.photoVerified,
                accountCreatedAt: isSelf ? ProductLifecycleStore.shared.installAt : nil,
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
