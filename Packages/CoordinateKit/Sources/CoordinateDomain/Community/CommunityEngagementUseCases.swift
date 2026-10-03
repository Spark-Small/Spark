//
//  CommunityEngagementUseCases.swift
//  CoordinateDomain
//
//  广场赞 / 藏 / 转计数规则（幂等）；表现层负责通知写回与 persist。
//

import Foundation
import CoordinateModels

public enum CommunityLikeChange: Equatable, Sendable {
    case liked(author: String, postID: UUID)
    case unliked(postID: UUID)
}

public enum CommunityRepostChange: Equatable, Sendable {
    case reposted(author: String, postID: UUID)
    case unreposted(postID: UUID)
}

public struct CommunityEngagementUseCases: Sendable {
    public init() {}

    @discardableResult
    public func toggleLike(
        postID: UUID,
        currentUserName: String,
        posts: inout [CommunityPost],
        likedIDs: inout Set<UUID>
    ) -> CommunityLikeChange? {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return nil }
        if likedIDs.contains(postID) {
            likedIDs.remove(postID)
            posts[index].likeCount = max(posts[index].likeCount - 1, 0)
            posts[index].likerNames.removeAll { $0 == currentUserName }
            return .unliked(postID: postID)
        }
        likedIDs.insert(postID)
        posts[index].likeCount += 1
        if !posts[index].likerNames.contains(currentUserName) {
            posts[index].likerNames.insert(currentUserName, at: 0)
        }
        return .liked(author: posts[index].author, postID: postID)
    }

    public func saveBookmark(
        postID: UUID,
        collection: String,
        bookmarkedIDs: inout Set<UUID>,
        bookmarkCollections: inout [UUID: String]
    ) {
        bookmarkedIDs.insert(postID)
        bookmarkCollections[postID] = collection
    }

    public func removeBookmark(
        postID: UUID,
        bookmarkedIDs: inout Set<UUID>,
        bookmarkCollections: inout [UUID: String]
    ) {
        bookmarkedIDs.remove(postID)
        bookmarkCollections[postID] = nil
    }

    public func recordShare(
        postID: UUID,
        posts: inout [CommunityPost]
    ) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].shareCount += 1
    }

    /// 仅处理「取消转发」；创建转发帖仍由 Feature Compose 侧组装正文。
    @discardableResult
    public func unrepost(
        postID: UUID,
        currentUserName: String,
        posts: inout [CommunityPost],
        repostedIDs: inout Set<UUID>
    ) -> CommunityRepostChange? {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return nil }
        guard repostedIDs.contains(postID) else { return nil }
        repostedIDs.remove(postID)
        posts[index].repostCount = max(posts[index].repostCount - 1, 0)
        posts.removeAll { $0.repostedFromID == postID && $0.author == currentUserName }
        return .unreposted(postID: postID)
    }

    public func markReposted(
        originalPostID: UUID,
        posts: inout [CommunityPost],
        repostedIDs: inout Set<UUID>
    ) -> CommunityRepostChange? {
        guard let index = posts.firstIndex(where: { $0.id == originalPostID }) else { return nil }
        if !repostedIDs.contains(originalPostID) {
            repostedIDs.insert(originalPostID)
            posts[index].repostCount += 1
        }
        return .reposted(author: posts[index].author, postID: originalPostID)
    }
}
