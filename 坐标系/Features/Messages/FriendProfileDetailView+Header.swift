//
//  FriendProfileDetailView+Header.swift
//  坐标系
//
//  好友资料顶区：头像身份 + 认证徽章按钮 + 社交计数 / 简介标签。
//

import SwiftUI
import CoordinateModels

extension FriendProfileDetailView {
    var contactHeader: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                PlatformListAvatarView(
                    name: nickname,
                    side: PlatformConversationListRow.imageSide * 1.85
                )

                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(displayName)
                        .font(PlatformListTypography.title3Emphasized)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(identitySecondaryLine)
                        .font(PlatformListTypography.captionEmphasized)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if !profileMetaLine.isEmpty {
                        Text(profileMetaLine)
                            .font(PlatformListTypography.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            credentialBadgeButtons

            if !publicBadges.isEmpty {
                TrustBadgeShowcase(earned: publicBadges, mode: .publicEarned)
            }

            ProfileSocialStatsRow(
                postCount: ProfileSocialStats.postCount(for: nickname, community: community),
                followingCount: ProfileSocialStats.followingCount(for: nickname, app: app),
                fansCount: ProfileSocialStats.fansCount(for: nickname, app: app)
            )

            if !bio.isEmpty {
                Text(bio)
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
            }

            if !tags.isEmpty {
                TagFlow(tags: tags)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .contain)
    }

    /// 形象认证 / 会员：可点进信任档案（灰态亦展示，避免顶区空荡）。
    private var credentialBadgeButtons: some View {
        NavigationLink {
            TrustPublicPreviewView(nickname: nickname, buddyItem: buddyItem)
                .toolbarVisibility(.hidden, for: .tabBar)
        } label: {
            HStack(spacing: PlatformMetrics.minContentGap) {
                TrustCredentialBadgeStrip(
                    photoVerified: trustFlags.photoVerified,
                    isMember: trustFlags.isMember,
                    revealLocked: true
                )
                Spacer(minLength: 0)
                Text(MessagesCopy.friendTrustArchiveLink)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(MessagesCopy.friendTrustArchiveLink)
        .accessibilityHint(MessagesCopy.friendTrustArchiveHint)
    }

    private var identitySecondaryLine: String {
        if showsNicknameAside {
            return "\(MessagesCopy.friendNicknameLabel) \(nickname)"
        }
        if let role = profileRoleLabel {
            return role
        }
        return MessagesCopy.friendRelationLabel
    }

    private var profileMetaLine: String {
        var parts: [String] = []
        if let profile {
            let city = profile.city.trimmingCharacters(in: .whitespacesAndNewlines)
            if !city.isEmpty { parts.append(city) }
            if profile.age > 0 { parts.append("\(profile.age) 岁") }
            let availability = profile.availability.trimmingCharacters(in: .whitespacesAndNewlines)
            if !availability.isEmpty { parts.append(availability) }
        }
        return parts.joined(separator: " · ")
    }

    private var profileRoleLabel: String? {
        switch buddyItem {
        case .paid: return MessagesCopy.friendRoleCompanion
        case .free: return MessagesCopy.friendRoleBuddy
        case .none: return nil
        }
    }
}
