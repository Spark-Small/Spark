// Module: SparkCommunity — Shared mock post data for list and detail.

import Foundation

enum MockCommunityPostCatalog {
    static func defaultReplies() -> [String: [CommunityPostReply]] {
        [
            "cp_1": [
                CommunityPostReply(
                    id: "cpr_1",
                    body: String(
                        localized: "community.mock.reply.1",
                        defaultValue: "周六可以，几点集合？",
                        comment: "Mock reply"
                    ),
                    authorDisplayName: String(
                        localized: "community.mock.2.author",
                        defaultValue: "小雨",
                        comment: "Author"
                    ),
                    createdAt: Date(timeIntervalSince1970: 1_749_000_000)
                )
            ]
        ]
    }

    static func allPosts(replyStore: [String: [CommunityPostReply]] = defaultReplies()) -> [CommunityPostDetail] {
        postStubs(replyStore: replyStore).map { detail in
            let replies = replyStore[detail.id, default: []]
            return CommunityPostDetail(
                id: detail.id,
                title: detail.title,
                body: detail.body,
                authorDisplayName: detail.authorDisplayName,
                authorUserID: detail.authorUserID,
                replyCount: max(detail.replyCount, replies.count),
                replies: replies,
                linkedActivity: detail.linkedActivity
            )
        }
    }

    private static func postStubs(replyStore: [String: [CommunityPostReply]]) -> [CommunityPostDetail] {
        [
            CommunityPostDetail(
                id: "cp_1",
                title: String(
                    localized: "community.mock.1.title",
                    defaultValue: "周末去哪玩？",
                    comment: "Community post"
                ),
                body: String(
                    localized: "community.mock.1.body",
                    defaultValue: "城郊步道周六上午集合，还差两人。有兴趣的留言或私信。",
                    comment: "Community post body"
                ),
                authorDisplayName: String(
                    localized: "community.mock.1.author",
                    defaultValue: "阿乐",
                    comment: "Author"
                ),
                authorUserID: "u_host_1",
                replyCount: replyStore["cp_1", default: []].count,
                linkedActivity: LinkedActivityContext(
                    id: "act_001",
                    name: String(
                        localized: "community.mock.activity.hike",
                        defaultValue: "周末爬香山",
                        comment: "Activity"
                    )
                )
            ),
            CommunityPostDetail(
                id: "cp_2",
                title: String(
                    localized: "community.mock.2.title",
                    defaultValue: "跑步打卡第 30 天",
                    comment: "Community post"
                ),
                body: String(
                    localized: "community.mock.2.body",
                    defaultValue: "滨江 5km，配速 6 分。坚持一个月，膝盖状态不错。",
                    comment: "Community post body"
                ),
                authorDisplayName: String(
                    localized: "community.mock.2.author",
                    defaultValue: "小雨",
                    comment: "Author"
                ),
                replyCount: 5
            ),
            CommunityPostDetail(
                id: "cp_3",
                title: String(
                    localized: "community.mock.3.title",
                    defaultValue: "咖啡聊天局复盘",
                    comment: "Community post"
                ),
                body: String(
                    localized: "community.mock.3.body",
                    defaultValue: "上次聊天局氛围很好，下次想试试早场，人少更专注。",
                    comment: "Community post body"
                ),
                authorDisplayName: String(
                    localized: "community.mock.3.author",
                    defaultValue: "Nova",
                    comment: "Author"
                ),
                replyCount: replyStore["cp_3", default: []].count
            )
        ]
    }

    static func summary(from detail: CommunityPostDetail) -> CommunityPost {
        let kind: CommunityPostKind = detail.title.localizedStandardContains(
            String(localized: "community.recap.keyword", defaultValue: "复盘", comment: "Recap keyword")
        ) ? .activityRecap : .discussion
        return CommunityPost(
            id: detail.id,
            title: detail.title,
            excerpt: String(detail.body.prefix(80)),
            authorDisplayName: detail.authorDisplayName,
            replyCount: detail.replyCount,
            kind: kind,
            linkedActivityID: detail.linkedActivity?.id,
            linkedActivityTitle: detail.linkedActivity?.name
        )
    }
}
