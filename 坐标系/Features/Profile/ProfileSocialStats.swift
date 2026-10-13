//
//  ProfileSocialStats.swift
//  坐标系
//
//  「我的」社交四列 UI + 本机可知边统计（无 Sample 粉丝/关注假数）。
//

import SwiftUI
import CoordinateModels

/// 获赞 / 互关 / 关注 / 粉丝：等宽四列；每列 = subtitleCell 主/副文（默认行高）。
struct ProfileSocialStatsRow: View {
    let likesCount: Int
    let mutualCount: Int
    let followingCount: Int
    let fansCount: Int
    var onLikesTap: (() -> Void)? = nil
    var onMutualTap: (() -> Void)? = nil
    var onFollowingTap: (() -> Void)? = nil
    var onFansTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            cell(
                value: "\(likesCount)",
                label: ProfileSocialCopy.likesLabel,
                hint: onLikesTap == nil ? nil : ProfileSocialCopy.likesAccessibilityHint,
                action: onLikesTap
            )
            cell(
                value: "\(mutualCount)",
                label: ProfileSocialCopy.mutualLabel,
                action: onMutualTap
            )
            cell(
                value: "\(followingCount)",
                label: ProfileSocialCopy.followingLabel,
                action: onFollowingTap
            )
            cell(
                value: "\(fansCount)",
                label: ProfileSocialCopy.fansLabel,
                action: onFansTap
            )
        }
    }

    @ViewBuilder
    private func cell(
        value: String,
        label: String,
        hint: String? = nil,
        action: (() -> Void)?
    ) -> some View {
        let content = VStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
            Text(value)
                .font(PlatformListTypography.primary)
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(PlatformListTypography.secondary)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label) \(value)")

        if let action {
            Button(action: action) { content }
                .buttonStyle(.plain)
                .accessibilityHint(hint ?? ProfileSocialCopy.openProfileHint)
        } else {
            content
        }
    }
}

@MainActor
enum ProfileSocialStats {
    #if DEBUG
    /// DEBUG 预览用本人粉丝昵称（搭子样板 nick，便于叠封面）；Release 不编译。
    private static let debugPreviewFanNicknames = [
        "Mia", "阿凯", "林夏", "小周", "Yuna", "Leo", "阿哲"
    ]
    /// DEBUG 预览用本人关注（与真实 `followedUserNames` 合并展示）。
    private static let debugPreviewFollowingNicknames = ["Leo", "Yuna", "小周", "Noon"]
    #endif

    /// 原创帖获赞合计（不含转发）。
    static func likesReceived(for name: String, community: CommunityModel) -> Int {
        community.posts
            .filter {
                $0.author.caseInsensitiveCompare(name) == .orderedSame
                    && $0.repostedFromID == nil
            }
            .reduce(0) { $0 + $1.likeCount }
    }

    /// 「我的发帖」入口角标：与列表默认「全部」一致（原创 + 转发）。
    static func postCount(for name: String, community: CommunityModel) -> Int {
        community.posts.filter {
            $0.author.caseInsensitiveCompare(name) == .orderedSame
        }.count
    }

    /// 互关：本机可知「已关注 ∩ 已是好友」；无反向关注图，不注 Sample。
    static func mutualCount(for name: String, app: AppModel, messages: MessagesModel) -> Int {
        names(for: .mutual, subject: name, app: app, messages: messages).count
    }

    static func followingCount(for name: String, app: AppModel) -> Int {
        if name.caseInsensitiveCompare(app.user.name) == .orderedSame {
            #if DEBUG
            return followingNamesForSelf(app: app).count
            #else
            return app.followedUserNames.count
            #endif
        }
        return 0
    }

    static func fansCount(for name: String, app: AppModel) -> Int {
        if name.caseInsensitiveCompare(app.user.name) == .orderedSame {
            #if DEBUG
            return debugPreviewFanNicknames.count
            #else
            return 0
            #endif
        }
        return app.isFollowing(name) ? 1 : 0
    }

    /// 「我的」社交图名单（已排序）；他人资料仅返回可知边，不造假列表。
    static func names(
        for kind: ProfileSocialGraphKind,
        app: AppModel,
        messages: MessagesModel
    ) -> [String] {
        names(for: kind, subject: app.user.name, app: app, messages: messages)
    }

    static func names(
        for kind: ProfileSocialGraphKind,
        subject: String,
        app: AppModel,
        messages: MessagesModel
    ) -> [String] {
        let isSelf = subject.caseInsensitiveCompare(app.user.name) == .orderedSame
        switch kind {
        case .mutual:
            guard isSelf else {
                let friends = friendNicknames(in: messages)
                let isFollowed = app.isFollowing(subject)
                let isFriend = friends.contains { $0.caseInsensitiveCompare(subject) == .orderedSame }
                return isFollowed && isFriend ? [subject] : []
            }
            let friends = friendNicknames(in: messages)
            return app.followedUserNames
                .filter { friend in
                    friends.contains { $0.caseInsensitiveCompare(friend) == .orderedSame }
                }
                .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        case .following:
            guard isSelf else { return [] }
            #if DEBUG
            return followingNamesForSelf(app: app)
            #else
            return app.followedUserNames.sorted {
                $0.localizedStandardCompare($1) == .orderedAscending
            }
            #endif
        case .fans:
            if isSelf {
                #if DEBUG
                return debugPreviewFanNicknames.sorted {
                    $0.localizedStandardCompare($1) == .orderedAscending
                }
                #else
                return []
                #endif
            }
            return app.isFollowing(subject) ? [app.user.name] : []
        }
    }

    #if DEBUG
    private static func followingNamesForSelf(app: AppModel) -> [String] {
        var merged = app.followedUserNames
        merged.formUnion(debugPreviewFollowingNicknames)
        return merged.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }
    #endif

    private static func friendNicknames(in messages: MessagesModel) -> Set<String> {
        Set(
            messages.conversations.compactMap { conversation in
                guard conversation.isFriendChat,
                      conversation.isFriend,
                      !conversation.isMessageRequest
                else { return nil }
                let title = conversation.title.trimmingCharacters(in: .whitespacesAndNewlines)
                return title.isEmpty ? nil : title
            }
        )
    }
}
