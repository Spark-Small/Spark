// Module: SparkCommunity — Mock tab feed, communities, and people discovery.

import Foundation
import SparkCore

enum MockCommunityTabCatalog {
    static func joinedCommunities() -> [CommunitySummary] {
        [
            CommunitySummary(
                id: "cm_hike",
                name: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
                coverURL: URL(string: "https://picsum.photos/seed/cm-hike/112/112"),
                memberCount: 38,
                activityCount: 12,
                hasNewPosts: true,
                bio: String(localized: "community.mock.hike.bio", defaultValue: "一起去爬山的人都不会太差", comment: "Bio")
            ),
            CommunitySummary(
                id: "cm_book",
                name: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
                coverURL: URL(string: "https://picsum.photos/seed/cm-book/112/112"),
                memberCount: 21,
                activityCount: 4,
                hasNewPosts: false
            ),
            CommunitySummary(
                id: "cm_photo",
                name: String(localized: "community.mock.photo", defaultValue: "摄影组", comment: "Community"),
                coverURL: URL(string: "https://picsum.photos/seed/cm-photo/112/112"),
                memberCount: 54,
                activityCount: 8,
                hasNewPosts: true
            )
        ]
    }

    static func allCommunities() -> [CommunitySummary] {
        joinedCommunities() + [
            CommunitySummary(
                id: "cm_run",
                name: String(localized: "community.mock.run", defaultValue: "晨跑打卡", comment: "Community"),
                coverURL: URL(string: "https://picsum.photos/seed/cm-run/112/112"),
                memberCount: 67,
                activityCount: 20,
                bio: String(localized: "community.mock.run.bio", defaultValue: "滨江沿线，配速随缘", comment: "Bio")
            )
        ]
    }

    static func feedPosts() -> [CommunityFeedPost] {
        feedPostsBatchOne() + feedPostsBatchTwo()
    }

    private static func feedPostsBatchOne() -> [CommunityFeedPost] {
        let hikeActivity = SharedActivityContext(
            id: "act_001",
            name: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
        )
        let now = Date()
        return [
            CommunityFeedPost(
                id: "cp_recap_mock",
                authorDisplayName: String(localized: "community.mock.3.author", defaultValue: "Nova", comment: "Author"),
                authorUserID: "u_guest_1",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_guest_1"),
                communityName: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.activityShare",
                    defaultValue: "玉林咖啡局氛围很好，认识了几位新朋友，下次还想来。",
                    comment: "Activity share feed post"
                ),
                imageURL: URL(string: "https://picsum.photos/seed/feed-recap/800/450"),
                mediaItems: SparkGalleryMediaFactory.mockActivityGallery(activityID: "act_browse_2"),
                likeCount: 9,
                commentCount: 2,
                createdAt: now.addingTimeInterval(-7_200),
                linkedActivity: LinkedActivityContext(
                    id: "act_browse_2",
                    name: String(localized: "community.mock.activity.book", defaultValue: "咖啡聊天局", comment: "Activity")
                ),
                kind: .activityRecap
            ),
            CommunityFeedPost(
                id: "cp_1",
                authorDisplayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
                authorUserID: "u_host_1",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_host_1"),
                communityName: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.1",
                    defaultValue: "昨天的山顶日出太美了！推荐大家周末一起走香山大环线。",
                    comment: "Feed post"
                ),
                imageURL: URL(string: "https://picsum.photos/seed/feed-1/800/450"),
                likeCount: 24,
                commentCount: 6,
                tags: [
                    String(localized: "community.mock.tag.hike", defaultValue: "爬山", comment: "Tag"),
                    String(localized: "community.mock.tag.weekend", defaultValue: "周末", comment: "Tag")
                ],
                createdAt: now.addingTimeInterval(-10_800),
                sharedActivityWithViewer: hikeActivity,
                linkedActivity: LinkedActivityContext(id: "act_001", name: hikeActivity.name)
            ),
            CommunityFeedPost(
                id: "cp_2",
                authorDisplayName: String(localized: "community.mock.2.author", defaultValue: "小雨", comment: "Author"),
                authorUserID: "u_host_2",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_host_2"),
                communityName: String(localized: "community.mock.book", defaultValue: "读书会", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.2",
                    defaultValue: "滨江 5km，配速 6 分。坚持一个月，膝盖状态不错。",
                    comment: "Feed post"
                ),
                likeCount: 11,
                commentCount: 5,
                tags: [String(localized: "community.mock.tag.run", defaultValue: "跑步", comment: "Tag")],
                createdAt: now.addingTimeInterval(-86_400)
            ),
            CommunityFeedPost(
                id: "cp_3",
                authorDisplayName: String(localized: "community.mock.3.author", defaultValue: "Nova", comment: "Author"),
                authorUserID: "u_guest_1",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_guest_1"),
                communityName: String(localized: "community.mock.photo", defaultValue: "摄影组", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.3",
                    defaultValue: "上次聊天局氛围很好，下次想试试早场，人少更专注。",
                    comment: "Feed post"
                ),
                imageURL: nil,
                likeCount: 8,
                commentCount: 2,
                tags: [],
                createdAt: now.addingTimeInterval(-172_800)
            )
        ]
    }

    private static func feedPostsBatchTwo() -> [CommunityFeedPost] {
        let now = Date()
        return [
            CommunityFeedPost(
                id: "cp_4",
                authorDisplayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
                authorUserID: "u_host_1",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_host_1"),
                communityName: String(localized: "community.mock.hike", defaultValue: "爬山队", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.4",
                    defaultValue: "城郊步道周六上午集合，还差两人。",
                    comment: "Feed post"
                ),
                likeCount: 5,
                commentCount: 3,
                tags: [],
                createdAt: now.addingTimeInterval(-200_000)
            ),
            CommunityFeedPost(
                id: "cp_5",
                authorDisplayName: String(localized: "community.mock.2.author", defaultValue: "小雨", comment: "Author"),
                authorUserID: "u_host_2",
                authorAvatarURL: MockCommunityAvatarCatalog.authorAvatarURL(userID: "u_host_2"),
                communityName: String(localized: "community.mock.run", defaultValue: "晨跑打卡", comment: "Community"),
                content: String(
                    localized: "community.mock.feed.5",
                    defaultValue: "今天云层很厚，但跑完心情很好。",
                    comment: "Feed post"
                ),
                imageURL: URL(string: "https://picsum.photos/seed/feed-5/800/450"),
                likeCount: 16,
                commentCount: 4,
                tags: [],
                createdAt: now.addingTimeInterval(-250_000)
            )
        ]
    }

    static func feedItems() -> [CommunityFeedItem] {
        feedPosts().map { .post($0) }
    }

    static func tabExperience(joinedIDs: Set<String>? = nil) -> CommunityTabExperience {
        let defaultJoined = Set(joinedCommunities().map(\.id))
        let joinedSet = joinedIDs ?? defaultJoined
        let joined = allCommunities().filter { joinedSet.contains($0.id) }
        return CommunityTabExperience(
            joinedCommunities: joined,
            feedItems: feedItems(),
            allCommunities: allCommunities()
        )
    }

    /// Builds detail payload when a feed card id is not in `MockCommunityPostCatalog`.
    static func postDetail(
        for feedPost: CommunityFeedPost,
        replies: [CommunityPostReply] = []
    ) -> CommunityPostDetail {
        let title: String
        if feedPost.kind == .activityRecap, let linked = feedPost.linkedActivity {
            let format = String(
                localized: "community.activityShare.postTitle.format",
                defaultValue: "「%@」局后随拍",
                comment: "Activity share post title; %@ activity title"
            )
            title = String(format: format, locale: .current, linked.name)
        } else {
            title = String(feedPost.content.prefix(40))
        }
        return CommunityPostDetail(
            id: feedPost.id,
            title: title,
            body: feedPost.content,
            authorDisplayName: feedPost.authorDisplayName,
            authorUserID: feedPost.authorUserID,
            replyCount: max(feedPost.commentCount, replies.count),
            replies: replies,
            linkedActivity: feedPost.linkedActivity,
            mediaItems: feedPost.galleryMedia,
            tags: feedPost.tags
        )
    }
}
