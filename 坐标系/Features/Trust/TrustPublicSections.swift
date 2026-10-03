//
//  TrustPublicSections.swift
//  坐标系
//
//  信任档案（对外）：等级 + 奖章墙 + 近 90 天事实。
//  奖章只展示已点亮视觉格；无徽章时不写空态说明文（对陌生人无意义）。
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
                isGuest: false,
                hasPhone: isSelf && !app.auth.phoneNumber.isEmpty,
                photoVerified: flags.photoVerified,
                accountCreatedAt: isSelf ? lifecycle.installAt : nil,
                friendCount: 0,
                liveHostedCount: liveHostedCount
            )
        )
    }

    var body: some View {
        let data = card

        Section {
            TrustLevelStrip(level: data.level)

            if !compact {
                TrustBadgeShowcase(earned: data.badges, mode: .publicEarned)
            }

            if isSelf {
                publicVerificationPhotosRow
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
                Text("奖章为已点亮凭证；会员标识不在信任档案中；履约事实来自近 90 天行为记录。")
            }
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
