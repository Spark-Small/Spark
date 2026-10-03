//
//  CommunityModel+Compose.swift
//  坐标系
//

import Foundation
import CoordinateDomain
import CoordinateModels

extension CommunityModel {
    func createRepost(of id: CommunityPost.ID, quote: String?) {
        guard let original = post(id: id) else { return }
        let quoteTrimmed = quote?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let quoteTrimmed, !quoteTrimmed.isEmpty,
           case .block = ContentModeration.scanText(quoteTrimmed) {
            return
        }
        if let change = engagement.markReposted(
            originalPostID: id,
            posts: &posts,
            repostedIDs: &repostedIDs
        ), case .reposted(let author, let postID) = change {
            recordCommunityInbox(
                kind: "repost",
                title: "\(currentUserName) 转发了你的分享",
                body: original.messageText,
                postID: postID,
                author: author
            )
        }
        posts.insert(
            CommunityPost(
                id: UUID(),
                author: currentUserName,
                title: "",
                body: quoteTrimmed?.isEmpty == false
                    ? (quoteTrimmed ?? "")
                    : original.body,
                tags: original.tags,
                likeCount: 0,
                commentCount: 0,
                repostCount: 0,
                shareCount: 0,
                postedAt: .now,
                isPinned: false,
                photoSeeds: [],
                photoHue: original.photoHue,
                localPhotoNames: [],
                relatedActivityTitle: original.relatedActivityTitle,
                relatedActivityID: original.relatedActivityID,
                comments: [],
                likerNames: [],
                repostedFromID: original.id,
                quoteText: quoteTrimmed?.isEmpty == false ? quoteTrimmed : nil
            ),
            at: 0
        )
        persist()
    }

    func publish(
        body: String,
        tags: [String],
        relatedActivityTitle: String?,
        relatedActivityID: UUID? = nil,
        localPhotoNames: [String]
    ) -> CommunityPublishResult {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return .invalid }
        if case .block = ContentModeration.scanText(trimmedBody) {
            return .blocked(ContentModeration.containsSensitive(trimmedBody) ?? "敏感内容")
        }

        let seedBase = Int.random(in: 1000...9000)
        let postID = UUID()
        posts.insert(
            CommunityPost(
                id: postID,
                author: currentUserName,
                title: "",
                body: trimmedBody,
                tags: tags,
                likeCount: 0,
                commentCount: 0,
                repostCount: 0,
                shareCount: 0,
                postedAt: .now,
                isPinned: false,
                photoSeeds: localPhotoNames.isEmpty ? [seedBase] : [],
                photoHue: Double.random(in: 0...1),
                localPhotoNames: localPhotoNames,
                relatedActivityTitle: relatedActivityTitle,
                relatedActivityID: relatedActivityID,
                comments: [],
                likerNames: []
            ),
            at: 0
        )
        presentation.endCompose()
        presentation.clearPendingCompose()
        presentation.flash(CommunityBrowseCopy.publishSuccess)
        persist()
        return .published(postID)
    }
}
