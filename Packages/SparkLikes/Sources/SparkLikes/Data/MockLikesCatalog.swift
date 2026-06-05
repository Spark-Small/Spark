// Module: SparkLikes — Mock discover profiles.

import Foundation
import SparkCore

enum MockLikesCatalog {
    // REASONING: u_like_2 mutual-matches on like for pairing demo.
    static let mutualMatchUserID = UserID("u_like_2")
    static let inboundUserID = UserID("u_like_5")

    static func allCards() -> [DiscoverCard] {
        [
            card1,
            card2,
            card3,
            card4
        ]
    }

    static func inboundCards() -> [DiscoverCard] {
        inboundItems().map(\.card)
    }

    static func inboundItems() -> [InboundLikeItem] {
        [
            InboundLikeItem(
                userID: inboundUserID,
                card: inboundCard,
                likedAt: Date().addingTimeInterval(-3_600),
                intensity: .spark,
                opener: String(
                    localized: "likes.mock.inbound.opener1",
                    defaultValue: "你的笑容很治愈",
                    comment: "Mock inbound opener"
                )
            ),
            InboundLikeItem(
                userID: UserID("u_like_6"),
                card: inboundCard2,
                likedAt: Date().addingTimeInterval(-7_200),
                opener: String(
                    localized: "likes.mock.inbound.opener2",
                    defaultValue: "想和你去这个活动",
                    comment: "Mock inbound opener 2"
                )
            )
        ]
    }

    static func mockSparkQuestions() -> [SparkQuestion] {
        [
            SparkQuestion(
                id: "sq_1",
                question: String(
                    localized: "likes.mock.question1",
                    defaultValue: "周末最想做的事",
                    comment: "Mock spark question"
                ),
                answer: String(
                    localized: "likes.mock.answer1",
                    defaultValue: "徒步到山顶看日出",
                    comment: "Mock spark answer"
                )
            ),
            SparkQuestion(
                id: "sq_2",
                question: String(
                    localized: "likes.mock.question2",
                    defaultValue: "最近单曲循环",
                    comment: "Mock spark question 2"
                ),
                answer: String(
                    localized: "likes.mock.answer2",
                    defaultValue: "City pop 老歌",
                    comment: "Mock spark answer 2"
                )
            )
        ]
    }

    static func card(userID: UserID) -> DiscoverCard? {
        (allCards() + inboundCards()).first { $0.userID == userID }
    }

    static func directThreadID(for userID: UserID) -> String {
        "th_dm_\(userID.rawValue)"
    }

    private static var card1: DiscoverCard {
        DiscoverCard(
            userID: UserID("u_like_1"),
            displayName: String(
                localized: "likes.mock.user1.name",
                defaultValue: "阿乐",
                comment: "Mock user"
            ),
            bio: String(
                localized: "likes.mock.user1.bio",
                defaultValue: "徒步、摄影、周末户外",
                comment: "Mock bio"
            ),
            gender: .male,
            media: DiscoverMedia(
                kind: .image,
                url: URL(string: "spark-likes://mock/u_like_1/a")!
            ),
            mediaItems: [
                DiscoverMedia(kind: .image, url: URL(string: "spark-likes://mock/u_like_1/a")!),
                DiscoverMedia(kind: .image, url: URL(string: "spark-likes://mock/u_like_1/b")!)
            ],
            interestTags: ["徒步", "摄影"],
            coarseLocation: String(
                localized: "likes.mock.user1.location",
                defaultValue: "上海",
                comment: "Mock location"
            ),
            sharedActivityTitle: String(
                localized: "likes.mock.sharedActivity",
                defaultValue: "周末 City Walk",
                comment: "Shared activity"
            ),
            sharedActivityID: "act_mock_walk",
            sparkQuestions: mockSparkQuestions(),
            isDailyPick: true
        )
    }

    private static var card2: DiscoverCard {
        DiscoverCard(
            userID: mutualMatchUserID,
            displayName: String(
                localized: "likes.mock.user2.name",
                defaultValue: "小雨",
                comment: "Mock user"
            ),
            bio: String(
                localized: "likes.mock.user2.bio",
                defaultValue: "咖啡、聊天、慢生活",
                comment: "Mock bio"
            ),
            gender: .female,
            media: DiscoverMedia(
                kind: .video,
                url: URL(string: "spark-likes://mock/u_like_2/video")!,
                posterURL: URL(string: "spark-likes://mock/u_like_2/poster")!
            ),
            interestTags: ["咖啡", "阅读"],
            coarseLocation: String(
                localized: "likes.mock.user2.location",
                defaultValue: "杭州",
                comment: "Mock location"
            )
        )
    }

    private static var card3: DiscoverCard {
        DiscoverCard(
            userID: UserID("u_like_3"),
            displayName: String(
                localized: "likes.mock.user3.name",
                defaultValue: "Nova",
                comment: "Mock user"
            ),
            bio: String(
                localized: "likes.mock.user3.bio",
                defaultValue: "跑步、健身、早起党",
                comment: "Mock bio"
            ),
            gender: .other,
            media: DiscoverMedia(
                kind: .image,
                url: URL(string: "spark-likes://mock/u_like_3")!
            ),
            interestTags: ["跑步"]
        )
    }

    private static var card4: DiscoverCard {
        DiscoverCard(
            userID: UserID("u_like_4"),
            displayName: String(
                localized: "likes.mock.user4.name",
                defaultValue: "书虫阿宁",
                comment: "Mock user"
            ),
            bio: String(
                localized: "likes.mock.user4.bio",
                defaultValue: "读书、分享、小局主持",
                comment: "Mock bio"
            ),
            gender: .female,
            media: DiscoverMedia(
                kind: .image,
                url: URL(string: "spark-likes://mock/u_like_4")!
            ),
            interestTags: ["读书", "分享"]
        )
    }

    private static var inboundCard: DiscoverCard {
        DiscoverCard(
            userID: inboundUserID,
            displayName: String(
                localized: "likes.mock.user5.name",
                defaultValue: "小晨",
                comment: "Inbound mock user"
            ),
            bio: String(
                localized: "likes.mock.user5.bio",
                defaultValue: "想认识同好，一起参加活动",
                comment: "Inbound bio"
            ),
            gender: .female,
            media: DiscoverMedia(
                kind: .image,
                url: URL(string: "spark-likes://mock/u_like_5")!
            ),
            mediaItems: [
                DiscoverMedia(kind: .image, url: URL(string: "spark-likes://mock/u_like_5/a")!),
                DiscoverMedia(kind: .image, url: URL(string: "spark-likes://mock/u_like_5/b")!)
            ],
            interestTags: ["活动", "社交"],
            sharedActivityTitle: String(
                localized: "likes.mock.sharedActivity",
                defaultValue: "周末 City Walk",
                comment: "Shared activity"
            ),
            sharedActivityID: "act_mock_walk"
        )
    }

    private static var inboundCard2: DiscoverCard {
        DiscoverCard(
            userID: UserID("u_like_6"),
            displayName: String(
                localized: "likes.mock.user6.name",
                defaultValue: "阿南",
                comment: "Second inbound mock user"
            ),
            bio: String(
                localized: "likes.mock.user6.bio",
                defaultValue: "喜欢户外和摄影",
                comment: "Second inbound bio"
            ),
            gender: .male,
            media: DiscoverMedia(
                kind: .image,
                url: URL(string: "spark-likes://mock/u_like_6")!
            ),
            interestTags: ["摄影"]
        )
    }
}
