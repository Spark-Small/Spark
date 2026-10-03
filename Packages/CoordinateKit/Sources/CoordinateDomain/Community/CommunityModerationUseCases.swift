//
//  CommunityModerationUseCases.swift
//  CoordinateDomain
//
//  广场举报 / 删除本人帖规则。
//

import Foundation
import CoordinateModels

public struct CommunityModerationUseCases: Sendable {
    public init() {}

    /// 举报成功后由 Feature 隐藏本机信息流并开工单。
    @discardableResult
    public func reportPost(
        postID: UUID,
        posts: inout [CommunityPost],
        reportedIDs: inout Set<UUID>
    ) -> Bool {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return false }
        posts[index].reportCount += 1
        reportedIDs.insert(postID)
        return true
    }

    /// 仅作者可删；返回被删帖的本地媒体文件名供 Feature 清盘。
    public func deleteOwnPost(
        postID: UUID,
        currentUserName: String,
        posts: inout [CommunityPost],
        likedIDs: inout Set<UUID>,
        repostedIDs: inout Set<UUID>,
        bookmarkedIDs: inout Set<UUID>,
        bookmarkCollections: inout [UUID: String],
        reportedIDs: inout Set<UUID>
    ) -> [String]? {
        guard let index = posts.firstIndex(where: { $0.id == postID }),
              posts[index].isOwned(by: currentUserName)
        else { return nil }

        let mediaNames = posts[index].localPhotoNames
        likedIDs.remove(postID)
        repostedIDs.remove(postID)
        bookmarkedIDs.remove(postID)
        bookmarkCollections[postID] = nil
        reportedIDs.remove(postID)
        posts.remove(at: index)
        return mediaNames
    }
}
