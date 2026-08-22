//
//  CommunityCommentsStore.swift
//  坐标系
//
//  社区动态评论：委托 PlatformReviewsStore 统一持久化。
//

import Foundation

@MainActor
enum CommunityCommentsStore {
    private static func target(_ postID: CommunityPost.ID) -> PlatformReviewTarget {
        .community(postID)
    }

    static func comments(for postID: CommunityPost.ID) -> [CommunityComment] {
        PlatformReviewsStore.reviews(for: target(postID)).map(CommunityComment.init(platformReview:))
    }

    static func commentCount(for postID: CommunityPost.ID) -> Int {
        comments(for: postID).count
    }

    static func removeAll(for postID: CommunityPost.ID) {
        PlatformReviewsStore.removeAll(for: target(postID))
    }

    /// 将帖子内嵌评论迁入统一评论库，并清空帖子上的冗余副本。
    static func bootstrap(posts: inout [CommunityPost], likedCommentIDs: Set<UUID>) -> Bool {
        var didMigrate = false

        for index in posts.indices {
            let post = posts[index]
            let storeTarget = target(post.id)

            if !post.comments.isEmpty {
                let imported = post.comments.map { comment in
                    PlatformReview(
                        communityComment: comment,
                        isLiked: likedCommentIDs.contains(comment.id)
                    )
                }
                PlatformReviewsStore.importReviews(imported, for: storeTarget)
                didMigrate = true
            }

            posts[index].comments = []
            posts[index].commentCount = PlatformReviewsStore.reviews(for: storeTarget).count
        }

        return didMigrate
    }

    static func syncCommentCount(for postID: CommunityPost.ID, in posts: inout [CommunityPost]) {
        guard let index = posts.firstIndex(where: { $0.id == postID }) else { return }
        posts[index].commentCount = commentCount(for: postID)
        posts[index].comments = []
    }
}

extension CommunityComment {
    init(platformReview: PlatformReview) {
        self.init(
            id: platformReview.id,
            author: platformReview.author,
            text: platformReview.text,
            postedAt: platformReview.postedAt,
            parentID: platformReview.parentID,
            replyToAuthor: platformReview.replyToAuthor,
            likeCount: platformReview.likeCount,
            region: platformReview.region,
            isLiked: platformReview.isLiked,
            dislikeCount: platformReview.dislikeCount,
            isDisliked: platformReview.isDisliked
        )
    }
}
