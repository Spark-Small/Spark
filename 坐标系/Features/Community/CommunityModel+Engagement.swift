//
//  CommunityModel+Engagement.swift
//  坐标系
//

import Foundation
import CoordinateDomain
import CoordinateModels

extension CommunityModel {
    func toggleLike(_ id: CommunityPost.ID) {
        guard let change = engagement.toggleLike(
            postID: id,
            currentUserName: currentUserName,
            posts: &posts,
            likedIDs: &likedIDs
        ) else { return }
        persist()
        switch change {
        case .liked(let author, let postID):
            recordCommunityInbox(
                kind: "like",
                title: "\(currentUserName) 赞了你的分享",
                body: post(id: postID)?.messageText ?? "",
                postID: postID,
                author: author
            )
        case .unliked(let postID):
            revokeCommunityInbox(kind: "like", postID: postID)
        }
    }

    func saveBookmark(_ id: CommunityPost.ID, collection: String) {
        engagement.saveBookmark(
            postID: id,
            collection: collection,
            bookmarkedIDs: &bookmarkedIDs,
            bookmarkCollections: &bookmarkCollections
        )
        persist()
    }

    func removeBookmark(_ id: CommunityPost.ID) {
        engagement.removeBookmark(
            postID: id,
            bookmarkedIDs: &bookmarkedIDs,
            bookmarkCollections: &bookmarkCollections
        )
        persist()
    }

    func recordShare(_ id: CommunityPost.ID) {
        engagement.recordShare(postID: id, posts: &posts)
        persist()
    }
}
