//
//  MergeRemoteCommunitySnapshotUseCase.swift
//  CoordinateDomain
//
//  远程广场快照合并：远程帖 upsert；本机赞/藏/转/举报集合并集保留；禁止整包覆盖。
//

import Foundation
import CoordinateModels

public struct MergeRemoteCommunitySnapshotUseCase: Sendable {
    public init() {}

    public func execute(
        remote: CommunitySnapshot,
        previous: CommunitySnapshot
    ) -> CommunitySnapshot {
        CommunitySnapshot(
            posts: mergePosts(remote: remote.posts, previous: previous.posts),
            likedIDs: Array(Set(previous.likedIDs).union(remote.likedIDs)),
            repostedIDs: Array(Set(previous.repostedIDs).union(remote.repostedIDs)),
            bookmarkedIDs: Array(Set(previous.bookmarkedIDs).union(remote.bookmarkedIDs)),
            bookmarkCollections: mergeCollections(
                remote: remote.bookmarkCollections,
                previous: previous.bookmarkCollections
            ),
            reportedIDs: Array(Set(previous.reportedIDs).union(remote.reportedIDs)),
            likedCommentIDs: Array(Set(previous.likedCommentIDs).union(remote.likedCommentIDs))
        )
    }

    /// 远程同 id 覆盖正文类字段；本机独有帖保留（用户刚发尚未上云）。
    private func mergePosts(
        remote: [CommunityPost],
        previous: [CommunityPost]
    ) -> [CommunityPost] {
        var result: [CommunityPost] = []
        var seen = Set<UUID>()

        for remotePost in remote {
            seen.insert(remotePost.id)
            if let local = previous.first(where: { $0.id == remotePost.id }) {
                result.append(preferPost(local: local, remote: remotePost))
            } else {
                result.append(remotePost)
            }
        }

        for local in previous where !seen.contains(local.id) {
            result.append(local)
        }

        return result.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
            return $0.postedAt > $1.postedAt
        }
    }

    /// 计数取较大；本机评论若远程为空则保留本机评论；其余采信远程正文。
    private func preferPost(local: CommunityPost, remote: CommunityPost) -> CommunityPost {
        var merged = remote
        merged.likeCount = max(local.likeCount, remote.likeCount)
        merged.commentCount = max(local.commentCount, remote.commentCount)
        merged.repostCount = max(local.repostCount, remote.repostCount)
        merged.shareCount = max(local.shareCount, remote.shareCount)
        if remote.comments.isEmpty, !local.comments.isEmpty {
            merged.comments = local.comments
            merged.commentCount = max(merged.commentCount, local.comments.count)
        }
        if remote.localPhotoNames.isEmpty, !local.localPhotoNames.isEmpty {
            merged.localPhotoNames = local.localPhotoNames
        }
        if remote.likerNames.isEmpty, !local.likerNames.isEmpty {
            merged.likerNames = local.likerNames
        } else {
            var names = remote.likerNames
            for name in local.likerNames where !names.contains(name) {
                names.append(name)
            }
            merged.likerNames = names
        }
        return merged
    }

    private func mergeCollections(
        remote: [String: String],
        previous: [String: String]
    ) -> [String: String] {
        var merged = previous
        for (key, value) in remote {
            merged[key] = value
        }
        return merged
    }
}
