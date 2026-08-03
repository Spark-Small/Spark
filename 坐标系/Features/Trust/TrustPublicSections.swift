//
//  TrustPublicSections.swift
//  坐标系
//
//  信任档案：等级 + 徽章 + 近 90 天履约事实（Form Section，与「可约档期」同级字样）。
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

        if compact {
            Section {
                TrustLevelStrip(level: data.level)
                TrustCredentialBadgeStrip(
                    photoVerified: flags.photoVerified,
                    isMember: flags.isMember,
                    revealLocked: isSelf
                )
                TrustFactLabeledRows(
                    facts: data.facts,
                    responseHint: data.responseHint
                )
            } header: {
                Text(BuddyDetailCopy.trustArchiveTitle)
            }
        } else {
            Section {
                TrustLevelStrip(level: data.level)
                TrustCredentialBadgeStrip(
                    photoVerified: flags.photoVerified,
                    isMember: flags.isMember,
                    revealLocked: isSelf
                )
            } header: {
                Text(BuddyDetailCopy.trustArchiveTitle)
            }

            Section {
                if isSelf {
                    TrustCredentialStatusRows(
                        photoVerified: flags.photoVerified,
                        isMember: flags.isMember
                    )
                }
                TrustBadgeRow(badges: earnedExtraBadges(from: data.badges))
                if !isSelf,
                   !flags.photoVerified,
                   !flags.isMember,
                   earnedExtraBadges(from: data.badges).isEmpty {
                    Text("认证徽章将随形象认证与会员点亮。")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("认证与徽章")
            }

            Section {
                TrustFactLabeledRows(
                    facts: data.facts,
                    responseHint: data.responseHint
                )
            } header: {
                Text("近 90 天履约事实")
            }
        }
    }

    private func earnedExtraBadges(from badges: [TrustBadge]) -> [TrustBadge] {
        badges.filter { $0.kind != .photoVerified && $0.kind != .activeMember }
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
        .platformSecondaryPage()
    }
}
