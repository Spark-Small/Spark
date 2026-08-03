//
//  CreatorInsights.swift
//  坐标系
//
//  「我发布的」创作者表现：本机聚合主办活动与自有分享的互动数据。
//

import Foundation

struct CreatorActivityInsight: Identifiable, Hashable {
    let activity: Activity
    var commentCount: Int

    var id: Activity.ID { activity.id }

    var joinedCount: Int { activity.joined }

    var metricLine: String {
        var parts = ["报名 \(joinedCount)"]
        if commentCount > 0 {
            parts.append("评论 \(commentCount)")
        }
        return parts.joined(separator: " · ")
    }
}

struct CreatorPostInsight: Identifiable, Hashable {
    let post: CommunityPost

    var id: CommunityPost.ID { post.id }

    var metricLine: String {
        var parts: [String] = []
        if post.likeCount > 0 { parts.append("赞 \(post.likeCount)") }
        if post.commentCount > 0 { parts.append("评论 \(post.commentCount)") }
        if post.repostCount > 0 { parts.append("转发 \(post.repostCount)") }
        if post.shareCount > 0 { parts.append("分享 \(post.shareCount)") }
        if parts.isEmpty { return "暂无互动" }
        return parts.joined(separator: " · ")
    }
}

struct CreatorInsightsSnapshot: Hashable {
    var activities: [CreatorActivityInsight]
    var posts: [CreatorPostInsight]

    var publishedCount: Int { activities.count + posts.count }

    var totalJoined: Int { activities.reduce(0) { $0 + $1.joinedCount } }
    var totalActivityComments: Int { activities.reduce(0) { $0 + $1.commentCount } }
    var totalLikes: Int { posts.reduce(0) { $0 + $1.post.likeCount } }
    var totalPostComments: Int { posts.reduce(0) { $0 + $1.post.commentCount } }
    var totalReposts: Int { posts.reduce(0) { $0 + $1.post.repostCount } }
}

@MainActor
enum CreatorInsightsService {
    static func snapshot(
        activities: ActivitiesModel,
        community: CommunityModel
    ) -> CreatorInsightsSnapshot {
        let activityInsights = activities.hostedActivities
            .sorted { $0.date > $1.date }
            .map { activity in
                CreatorActivityInsight(
                    activity: activity,
                    commentCount: ActivityCommentsStore.comments(for: activity.id).count
                )
            }

        let postInsights = community.myPosts.map(CreatorPostInsight.init(post:))

        return CreatorInsightsSnapshot(
            activities: activityInsights,
            posts: postInsights
        )
    }
}
