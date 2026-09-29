//
//  BuddyDetailProfileHeader.swift
//  坐标系
//
//  搭子详情身份头与特质芯片。
//

import SwiftUI
import CoordinateModels

// MARK: - Identity

struct BuddyDetailProfileStat: Identifiable, Hashable {
    let id: String
    var value: String
    var label: String
}

struct BuddyDetailProfileHeaderConfig {
    var statusLine: String?
    var statusTint: Color = .secondary
    var traitTags: [String] = []
    var stats: [BuddyDetailProfileStat] = []
    var hotBadge: BuddyPaidHotBadge?
    var isVerified = false
    var isOnline = false
    var showsVoicePlay = false
    var rankIconCount = 0
}

@MainActor
enum BuddyDetailProfileHeaderFactory {
    static func free(buddy: CircleBuddy) -> BuddyDetailProfileHeaderConfig {
        let profile = buddy.profile
        let isOnline = buddy.isOnline && PrivacyPreferences.showOnline

        return BuddyDetailProfileHeaderConfig(
            statusLine: isOnline ? BuddyDetailCopy.online : nil,
            statusTint: PlatformStatus.success,
            traitTags: Array(profile.tags.prefix(3)),
            stats: [],
            isOnline: isOnline
        )
    }

    static func paid(companion: PaidCompanion) -> BuddyDetailProfileHeaderConfig {
        let profile = companion.profile
        let rankIcons = min(3, max(1, companion.orderCount / 40))
        let highlights = BuddyPaidMarketCatalog.leaderboardHighlights(for: companion, limit: 2)
        let tags = Array(profile.tags.prefix(1))

        return BuddyDetailProfileHeaderConfig(
            statusLine: companion.isAvailable
                ? BuddyDetailCopy.available
                : BuddyDetailCopy.unavailable,
            statusTint: companion.isAvailable ? PlatformStatus.success : .secondary,
            traitTags: tags + highlights,
            stats: [],
            hotBadge: BuddyPaidHotBadge.forCompanion(companion, rank: 1),
            isVerified: companion.isVerified,
            showsVoicePlay: companion.serviceType == .voice,
            rankIconCount: rankIcons
        )
    }
}

struct BuddyDetailTraitChip: View {
    let title: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: PlatformMetrics.hairlineSpacing) {
            Image(systemName: systemImage)
                .font(.caption2.weight(.semibold))
            Text(title)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

struct BuddyDetailProfileHeader: View {
    let profile: BuddyProfile
    let config: BuddyDetailProfileHeaderConfig
    var groupAlias: String? = nil
    var showsFollow = false
    var isFollowing = false
    var onToggleFollow: (() -> Void)?

    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var community

    private var displayNickname: String {
        GroupNicknameDisplay.formatted(realName: profile.nickname, groupAlias: groupAlias)
    }

    private var publicID: String {
        UserPublicID.formatDisplay(UserPublicID.code(for: profile.id))
    }

    private var cityLabel: String {
        profile.city.components(separatedBy: " · ").first ?? profile.city
    }

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
                    avatar

                    VStack(alignment: .leading, spacing: PlatformMetrics.minContentGap) {
                        titleRow
                        metaRow
                        if !displayTraitTags.isEmpty {
                            traitRow
                        }
                    }
                }

                if showsFollow {
                    Spacer(minLength: 0)
                    followButton
                }
            }

            ProfileSocialStatsRow(
                postCount: ProfileSocialStats.postCount(for: profile.nickname, community: community),
                followingCount: ProfileSocialStats.followingCount(for: profile.nickname, app: app),
                fansCount: ProfileSocialStats.fansCount(for: profile.nickname, app: app)
            )
        }
        .accessibilityElement(children: .combine)
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            CommunityRemotePhoto(ref: profile.coverPhoto)
                .frame(width: 72, height: 72)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(Color(.separator).opacity(0.35), lineWidth: 1)
                }

            if config.showsVoicePlay {
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.purple.opacity(0.92), in: Circle())
                    .overlay {
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: 2)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Circle())
                    .offset(x: 4, y: 4)
                    .accessibilityLabel("语音陪聊")
            } else if config.isOnline {
                Circle()
                    .fill(PlatformStatus.success)
                    .frame(width: 12, height: 12)
                    .overlay {
                        Circle().strokeBorder(Color(.systemBackground), lineWidth: 2)
                    }
                    .offset(x: 2, y: 2)
                    .accessibilityLabel(BuddyDetailCopy.online)
            }
        }
        .accessibilityHidden(true)
    }

    private var titleRow: some View {
        HStack(alignment: .center, spacing: PlatformMetrics.minContentGap) {
            Text(displayNickname)
                .font(.title3.weight(.bold))
                .foregroundStyle(.primary)
                .lineLimit(1)

            genderAgeBadge

            if let statusLine = config.statusLine {
                Text(statusLine)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(config.statusTint)
                    .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
                    .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
                    .background(config.statusTint.opacity(0.12), in: Capsule())
            }

            Spacer(minLength: 0)

            if config.rankIconCount > 0 {
                rankStack
            }
        }
    }

    private var genderAgeBadge: some View {
        HStack(spacing: 2) {
            Text(profile.gender.symbol)
                .font(.caption2.weight(.bold))
            Text("\(profile.age)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
        }
        .foregroundStyle(.white)
        .padding(.horizontal, PlatformMetrics.captionBadgePaddingHorizontal)
        .padding(.vertical, PlatformMetrics.captionBadgePaddingVertical)
        .background(profile.gender.tint.opacity(0.88), in: Capsule())
        .accessibilityLabel("\(profile.gender.rawValue)，\(BuddyDetailCopy.ageValue(profile.age))")
    }

    private var rankStack: some View {
        PlatformCompanionLevelStack(iconCount: config.rankIconCount)
    }

    private var metaRow: some View {
        HStack(spacing: PlatformMetrics.minContentGap) {
            Text("\(BuddyDetailCopy.profileIDPrefix):\(publicID)")
                .lineLimit(1)
            Text("·")
                .foregroundStyle(.quaternary)
            Label(cityLabel, systemImage: "mappin.and.ellipse")
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }

    private var displayTraitTags: [String] {
        Array(config.traitTags.prefix(3))
    }

    private var traitRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PlatformMetrics.hairlineSpacing) {
                if let hotBadge = config.hotBadge {
                    BuddyDetailTraitChip(
                        title: hotBadge.rawValue,
                        systemImage: "flame.fill",
                        tint: hotBadge.tint
                    )
                }
                if config.isVerified {
                    BuddyDetailTraitChip(
                        title: BuddyDetailCopy.verifiedBadge,
                        systemImage: "checkmark.seal.fill",
                        tint: Color.accentColor
                    )
                }
                ForEach(Array(displayTraitTags.enumerated()), id: \.offset) { index, tag in
                    let style = BuddyDetailProfileHeaderFactory.traitStyle(for: tag, index: index)
                    BuddyDetailTraitChip(
                        title: tag,
                        systemImage: style.icon,
                        tint: style.tint
                    )
                }
            }
        }
    }

    private var followButton: some View {
        Button {
            onToggleFollow?()
        } label: {
            Text(isFollowing ? "已关注" : "关注")
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 5)
        }
        .buttonStyle(.borderedProminent)
        .tint(isFollowing ? Color(.tertiarySystemFill) : .accentColor)
        .foregroundStyle(isFollowing ? Color.secondary : Color.white)
        .controlSize(.small)
    }
}

extension BuddyDetailProfileHeaderFactory {
    static func traitStyle(for tag: String, index: Int) -> (icon: String, tint: Color) {
        let presets: [(String, Color)] = [
            ("sparkles", .purple),
            ("leaf.fill", .pink),
            ("heart.fill", .orange),
            ("star.fill", .yellow),
            ("figure.run", .mint),
            ("camera.fill", .teal)
        ]
        if tag.localizedCaseInsensitiveContains("语音") || tag.localizedCaseInsensitiveContains("声音") {
            return ("waveform", .purple)
        }
        if tag.localizedCaseInsensitiveContains("徒步") || tag.localizedCaseInsensitiveContains("运动") {
            return ("figure.hiking", .mint)
        }
        let preset = presets[index % presets.count]
        return (BuddyHobbyOption.systemImage(for: tag), preset.1)
    }
}

