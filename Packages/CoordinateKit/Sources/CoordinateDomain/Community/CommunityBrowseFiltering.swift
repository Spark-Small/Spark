//
//  CommunityBrowseFiltering.swift
//  CoordinateDomain
//
//  广场筛选纯函数（无 UI Copy），供 Feature 与测例共用。
//

import Foundation
import CoordinateModels

public enum CommunityBrowseFilterKind: String, CaseIterable, Sendable, Hashable {
    case all
    case following
    case conversation
    case mention
    /// 发现向：未关注作者（与 `following` 互斥）。UI「发现作者」。
    case peopleYouFollow
}

public enum CommunityBrowseFiltering: Sendable {
    public static func posts(
        _ posts: [CommunityPost],
        filter: CommunityBrowseFilterKind,
        followedUserNames: Set<String>,
        currentUserName: String,
        joinedActivityTitles: Set<String>
    ) -> [CommunityPost] {
        switch filter {
        case .all:
            return posts
        case .following:
            return posts.filter { followedUserNames.contains($0.author) }
        case .peopleYouFollow:
            return posts.filter {
                $0.author != currentUserName && !followedUserNames.contains($0.author)
            }
        case .conversation:
            // UI「热议」：有人评论过的分享
            return posts.filter { $0.commentCount > 0 || !$0.comments.isEmpty }
        case .mention:
            // UI「与我相关」：关联已参加/主办活动，或正文提到当前用户
            let needle = currentUserName.trimmingCharacters(in: .whitespacesAndNewlines)
            return posts.filter { post in
                if let title = post.relatedActivityTitle, joinedActivityTitles.contains(title) {
                    return true
                }
                if !needle.isEmpty, post.messageText.localizedCaseInsensitiveContains(needle) {
                    return true
                }
                return false
            }
        }
    }

    public static func followCandidates(
        from posts: [CommunityPost],
        followedUserNames: Set<String>,
        currentUserName: String,
        limit: Int = 3
    ) -> [String] {
        var seen = Set<String>()
        var names: [String] = []
        for post in posts {
            let author = post.author
            guard author != currentUserName,
                  !followedUserNames.contains(author),
                  seen.insert(author).inserted
            else { continue }
            names.append(author)
            if names.count >= limit { break }
        }
        return names
    }

    public static func recommendedPost(
        from posts: [CommunityPost],
        currentUserName: String,
        followedUserNames: Set<String>
    ) -> CommunityPost? {
        posts
            .filter { $0.author != currentUserName }
            .sorted { lhs, rhs in
                let l = lhs.likeCount + lhs.commentCount + lhs.repostCount
                let r = rhs.likeCount + rhs.commentCount + rhs.repostCount
                if l != r { return l > r }
                return lhs.postedAt > rhs.postedAt
            }
            .first { !followedUserNames.contains($0.author) }
            ?? posts.first { $0.author != currentUserName }
    }

    /// 站内社区通知标题/正文是否点名已拉黑用户（预览与收件箱共用）。
    public static func communityNotificationMentionsBlocked(
        title: String,
        body: String,
        blockedUserNames: Set<String>
    ) -> Bool {
        blockedUserNames.contains { blocked in
            let needle = blocked.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !needle.isEmpty else { return false }
            return title.localizedCaseInsensitiveContains(needle)
                || body.localizedCaseInsensitiveContains(needle)
        }
    }
}
