//
//  CommunityModel+Moderation.swift
//  坐标系
//

import Foundation
import CoordinateDomain
import CoordinateModels

extension CommunityModel {
    func syncComments(for postID: CommunityPost.ID) {
        let previousCount = post(id: postID)?.commentCount ?? 0
        CommunityCommentsStore.syncCommentCount(for: postID, in: &posts)
        bumpComments()
        persist()

        let nextCount = post(id: postID)?.commentCount ?? 0
        guard nextCount > previousCount,
              let target = post(id: postID),
              let latest = CommunityCommentsStore.comments(for: postID).max(by: { $0.postedAt < $1.postedAt }),
              latest.author == currentUserName
        else { return }

        // 回复评论：通知被回复者；否则通知帖作者（均跳过本人）。
        if let replyTo = latest.replyToAuthor,
           !replyTo.isEmpty,
           replyTo != currentUserName {
            recordCommunityInbox(
                kind: "comment-reply",
                title: "\(currentUserName) 回复了你的评论",
                body: latest.text,
                postID: postID,
                author: replyTo
            )
        } else {
            recordCommunityInbox(
                kind: "comment",
                title: "\(currentUserName) 评论了你的分享",
                body: latest.text,
                postID: postID,
                author: target.author
            )
        }
    }

    func deletePost(_ id: CommunityPost.ID) -> Bool {
        guard let mediaNames = moderation.deleteOwnPost(
            postID: id,
            currentUserName: currentUserName,
            posts: &posts,
            likedIDs: &likedIDs,
            repostedIDs: &repostedIDs,
            bookmarkedIDs: &bookmarkedIDs,
            bookmarkCollections: &bookmarkCollections,
            reportedIDs: &reportedIDs
        ) else { return false }

        for name in mediaNames {
            LocalMediaLibrary.delete(named: name)
        }
        CommunityCommentsStore.removeAll(for: id)
        notificationInbox?.removeCommunityItems(forPostID: id)
        persist()
        return true
    }

    func reportPost(_ id: CommunityPost.ID, reason _: String) -> Bool {
        let ok = moderation.reportPost(
            postID: id,
            posts: &posts,
            reportedIDs: &reportedIDs
        )
        guard ok else { return false }
        persist()
        presentation.flash(CommunityBrowseCopy.reportSubmitted)
        return true
    }
}
