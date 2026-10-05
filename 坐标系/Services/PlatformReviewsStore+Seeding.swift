//
//  PlatformReviewsStore+Seeding.swift
//  坐标系
//
//  活动 / 社区评论的本机空库种子（DEBUG 体验）。陪玩评价不在此注入。
//

import Foundation
import CoordinateModels

extension PlatformReviewsStore {
    static func seedReviews(for target: PlatformReviewTarget) -> [PlatformReview] {
        switch target.kind {
        case .activity:
            guard let activityID = UUID(uuidString: target.id) else { return [] }
            return seedActivityComments(activityID: activityID)
        case .companion:
            // 诚实门控：无后端时不注入 Sample 假陪玩评价。
            return []
        case .community:
            guard let postID = UUID(uuidString: target.id) else { return [] }
            return seedCommunityComments(postID: postID)
        }
    }

    private static func seedCommunityComments(postID: CommunityPost.ID) -> [PlatformReview] {
        guard let post = SampleData.posts.first(where: { $0.id == postID }) else { return [] }
        return post.comments.map { PlatformReview(communityComment: $0) }
    }

    private static func seedActivityComments(activityID: Activity.ID) -> [PlatformReview] {
        guard let activity = SampleData.activities.first(where: { $0.id == activityID }) else {
            return []
        }
        let seeds: [(String, String, Int, Int)] = [
            ("Mia", "想确认一下集合地点具体在哪边？", -180, 12),
            ("阿凯", "还有名额吗？我可以带一位朋友吗？", -120, 5),
            ("小周", "上次参加过\(activity.hostName)的局，组织很靠谱。", -60, 21)
        ]
        let count = 1 + abs(activity.id.stableSeed % 3)
        var comments = seeds.prefix(count).map { author, text, minutes, likes in
            PlatformReview(
                author: author,
                text: text,
                postedAt: Date().addingTimeInterval(TimeInterval(minutes * 60)),
                likeCount: likes
            )
        }
        if let first = comments.first {
            comments.append(
                PlatformReview(
                    author: activity.hostName,
                    text: "门口白色标识那边集合，我提前 10 分钟到～",
                    postedAt: first.postedAt.addingTimeInterval(8 * 60),
                    parentID: first.id,
                    replyToAuthor: first.author,
                    likeCount: 3
                )
            )
        }
        return comments
    }
}
