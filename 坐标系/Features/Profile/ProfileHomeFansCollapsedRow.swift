//
//  ProfileHomeFansCollapsedRow.swift
//  坐标系
//
//  「我的」头区下方整行：叠头像按剩余宽度铺满（单行）+「N位粉丝/关注」。
//  槽位用宽度公式推算（GeometryReader 内算，无 @State / 无 ViewThatFits 多候选）。
//

import CoordinateModels
import SwiftUI

struct ProfileHomeFansCollapsedRow: View {
    @Environment(AppModel.self) private var app
    @Environment(MessagesModel.self) private var messages
    @Environment(BuddiesModel.self) private var buddies

    var onTap: () -> Void

    /// 单行硬上限：避免宽屏铺过多脸；溢出末位 +N。
    private static let maxStackSlots = 8

    private var sourceNames: [String] {
        let fans = ProfileSocialStats.names(for: .fans, app: app, messages: messages)
        if !fans.isEmpty { return fans }
        return ProfileSocialStats.names(for: .following, app: app, messages: messages)
    }

    private var fansCount: Int {
        ProfileSocialStats.fansCount(for: app.user.name, app: app)
    }

    private var followingCount: Int {
        ProfileSocialStats.followingCount(for: app.user.name, app: app)
    }

    private var caption: String {
        ProfileSocialCopy.collapsedSocialCaption(
            fansCount: fansCount,
            followingCount: followingCount
        )
    }

    private var avatarSide: CGFloat {
        PlatformConversationListRow.imageSide
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                if !sourceNames.isEmpty {
                    // 吃掉文案左侧剩余宽；槽位数在 Reader 内按公式算，避免试宽回环。
                    GeometryReader { geo in
                        let slots = Self.slotCount(
                            availableWidth: geo.size.width,
                            avatarSide: avatarSide,
                            total: sourceNames.count
                        )
                        avatarStack(slots: slots)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    }
                    .frame(height: avatarSide)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text(caption)
                    .font(PlatformListTypography.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(caption)
        .accessibilityHint(ProfileSocialCopy.openSocialGraphHint)
    }

    /// `width(n) = side + (n-1)·side·(1-overlap)`；结果夹在 1…max 与人数之间。
    private static func slotCount(
        availableWidth: CGFloat,
        avatarSide: CGFloat,
        total: Int
    ) -> Int {
        guard total > 0, availableWidth > 0, avatarSide > 0 else { return 0 }
        let step = avatarSide * (1 - PlatformMetrics.avatarStackOverlapFactor)
        guard step > 0 else { return min(1, total) }
        let maxByWidth: Int
        if availableWidth + 0.5 < avatarSide {
            maxByWidth = 0
        } else {
            maxByWidth = 1 + Int(floor((availableWidth - avatarSide) / step + 0.001))
        }
        return min(maxStackSlots, total, max(maxByWidth, 0))
    }

    @ViewBuilder
    private func avatarStack(slots: Int) -> some View {
        let total = sourceNames.count
        let capped = max(slots, 0)
        if capped > 0 {
            let showsOverflow = total > capped
            let faceCount = showsOverflow ? max(capped - 1, 0) : min(capped, total)
            let faces = Array(sourceNames.prefix(faceCount))
            let overflow = total - faceCount

            HStack(spacing: PlatformMetrics.avatarStackSpacing(avatarSide: avatarSide)) {
                ForEach(faces, id: \.self) { name in
                    PlatformListAvatarView(
                        name: name,
                        photoRef: ProfileSocialAvatarResolver.photoRef(
                            for: name,
                            buddies: buddies
                        ),
                        side: avatarSide
                    )
                    .overlay {
                        Circle().strokeBorder(
                            PlatformSurface.canvas,
                            lineWidth: PlatformMetrics.avatarBadgeStroke
                        )
                    }
                }

                if showsOverflow, overflow > 0 {
                    Text("+\(overflow)")
                        .font(PlatformListTypography.caption2Emphasized)
                        .foregroundStyle(.secondary)
                        .frame(width: avatarSide, height: avatarSide)
                        .background(PlatformSurface.tertiaryFill, in: Circle())
                        .overlay {
                            Circle().strokeBorder(
                                PlatformSurface.canvas,
                                lineWidth: PlatformMetrics.avatarBadgeStroke
                            )
                        }
                        .accessibilityHidden(true)
                }
            }
            .accessibilityHidden(true)
        }
    }
}
