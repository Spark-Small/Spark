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
                    photo: isSelf ? app.user.localAvatarImage : nil,
                    photoRef: isSelf ? nil : profile?.coverPhoto,
                    side: PlatformConversationListRow.imageSide * 1.85
                )

                VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(displayName)
                        .font(PlatformListTypography.title3Emphasized)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(1)

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
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            credentialBadgeButtons

            if !publicBadges.isEmpty {
                TrustBadgeShowcase(earned: publicBadges, mode: .publicEarned)
            }

            ProfileSocialStatsRow(
                likesCount: ProfileSocialStats.likesReceived(for: nickname, community: community),
                mutualCount: ProfileSocialStats.mutualCount(for: nickname, app: app, messages: model),
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
        let city = publicFields.city
        if !city.isEmpty { parts.append(city) }
        if isSelf, !publicFields.handle.isEmpty {
            parts.append("@\(publicFields.handle)")
        }
        if let gender = publicFields.gender {
            parts.append(gender.rawValue)
        }
        if let age = publicFields.age, age > 0 {
            parts.append("\(age) 岁")
        }
        if let height = publicFields.heightCM, height > 0 {
            parts.append("\(height)cm")
        }
        if !publicFields.availability.isEmpty {
            parts.append(publicFields.availability)
        } else if !publicFields.intentDisplayLine.isEmpty {
            parts.append(publicFields.intentDisplayLine)
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
