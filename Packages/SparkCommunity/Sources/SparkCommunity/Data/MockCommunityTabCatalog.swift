// Module: SparkCommunity — Mock tab feed, communities, and people discovery.

import Foundation

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

    static func discoveredPeople() -> [DiscoveredPerson] {
        [
            DiscoveredPerson(
                id: "u_like_1",
                displayName: String(localized: "community.mock.person.1", defaultValue: "李明", comment: "Person"),
                avatarURL: URL(string: "https://picsum.photos/seed/person-1/96/96"),
                sharedTag: String(localized: "community.mock.tag.hike", defaultValue: "爬山", comment: "Tag"),
                relationship: .sharedActivity(
                    String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
                )
            ),
            DiscoveredPerson(
                id: "u_like_2",
                displayName: String(localized: "community.mock.person.2", defaultValue: "王芳", comment: "Person"),
                avatarURL: URL(string: "https://picsum.photos/seed/person-2/96/96"),
                sharedTag: String(localized: "community.mock.tag.book", defaultValue: "读书", comment: "Tag"),
                relationship: .sharedActivity(
                    String(localized: "community.mock.activity.book", defaultValue: "咖啡聊天局", comment: "Activity")
                )
            ),
            DiscoveredPerson(
                id: "u_like_3",
                displayName: String(localized: "community.mock.person.3", defaultValue: "张伟", comment: "Person"),
                avatarURL: URL(string: "https://picsum.photos/seed/person-3/96/96"),
                sharedTag: String(localized: "community.mock.tag.photo", defaultValue: "摄影", comment: "Tag"),
                relationship: .liked
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
                id: "cp_1",
                authorDisplayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
                authorUserID: "u_host_1",
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
        var items: [CommunityFeedItem] = []
        let posts = feedPosts()
        let people = discoveredPeople()
        for (index, post) in posts.enumerated() {
            items.append(.post(post))
            if (index + 1) % 5 == 0 {
                items.append(.peopleDiscovery(people))
            }
        }
        return items
    }

    static func tabExperience() -> CommunityTabExperience {
        CommunityTabExperience(
            joinedCommunities: joinedCommunities(),
            feedItems: feedItems(),
            allCommunities: allCommunities()
        )
    }
}
