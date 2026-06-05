// Module: SparkActivity — Mock activity detail seed records.

import Foundation

extension MockActivityCatalog {
    static func seededDetails(
        saturday: Date,
        tonight: Date,
        tomorrowMorning: Date,
        lastWeek: Date,
        sundayAfternoon: Date
    ) -> [ActivityDetail] {
        return hikeAndCoffeeDetails(saturday: saturday, tonight: tonight)
            + runDetail(tomorrowMorning: tomorrowMorning)
            + endedAndBookClubDetails(lastWeek: lastWeek, sundayAfternoon: sundayAfternoon)
    }

    private static func hikeAndCoffeeDetails(saturday: Date, tonight: Date) -> [ActivityDetail] {
        [hikeDetail(startsAt: saturday), coffeeDetail(startsAt: tonight)]
    }

    private static func hikeDetail(startsAt: Date) -> ActivityDetail {
        let hikeHost = String(
            localized: "activity.item.1.host",
            defaultValue: "阿乐",
            comment: "Activity host"
        )

        return ActivityDetail(
                id: "act_1",
                title: String(
                    localized: "activity.item.1.title",
                    defaultValue: "周末徒步",
                    comment: "Activity item"
                ),
                summary: String(
                    localized: "activity.item.1.summary",
                    defaultValue: "城郊步道 · 周六上午",
                    comment: "Activity summary"
                ),
                category: String(
                    localized: "activity.category.event",
                    defaultValue: "活动",
                    comment: "Activity category"
                ),
                description: String(
                    localized: "activity.item.1.description",
                    defaultValue: "城郊步道轻徒步，约 8km。集合后统一出发，自备饮水。雨天顺延。",
                    comment: "Activity description"
                ),
                startsAt: startsAt,
                locationName: String(
                    localized: "activity.item.1.location",
                    defaultValue: "城郊步道北门",
                    comment: "Activity location"
                ),
                hostDisplayName: hikeHost,
                hostID: "host_hike",
                hostBio: String(
                    localized: "activity.item.1.hostBio",
                    defaultValue: "周末户外局常客，带队 3 年。",
                    comment: "Host bio"
                ),
                attendeeCount: 5,
                capacity: 8,
                rsvpStatus: .going,
                lifecycleStatus: .scheduled,
                attendees: MockActivityAttendees.roster(
                    host: hikeHost,
                    members: [("小林", true), ("阿哲", false), ("Mia", true), ("橙子", false)]
                ),
                conversationThreadID: ActivityThreadID.make(for: "act_1")
            )
    }

    private static func coffeeDetail(startsAt: Date) -> ActivityDetail {
        let coffeeHost = String(
            localized: "activity.item.2.host",
            defaultValue: "小雨",
            comment: "Activity host"
        )

        return ActivityDetail(
                id: "act_2",
                title: String(
                    localized: "activity.item.2.title",
                    defaultValue: "咖啡聊天局",
                    comment: "Activity item"
                ),
                summary: String(
                    localized: "activity.item.2.summary",
                    defaultValue: "三人小局 · 今晚",
                    comment: "Activity summary"
                ),
                category: String(
                    localized: "activity.category.social",
                    defaultValue: "社交",
                    comment: "Activity category"
                ),
                description: String(
                    localized: "activity.item.2.description",
                    defaultValue: "轻松聊天局，不聊工作。先到先坐，点单 AA。",
                    comment: "Activity description"
                ),
                startsAt: startsAt,
                locationName: String(
                    localized: "activity.item.2.location",
                    defaultValue: "静安寺咖啡馆",
                    comment: "Activity location"
                ),
                hostDisplayName: coffeeHost,
                hostID: "host_coffee",
                hostBio: String(
                    localized: "activity.item.2.hostBio",
                    defaultValue: "喜欢小局聊天，每周一晚。",
                    comment: "Host bio"
                ),
                attendeeCount: 4,
                capacity: 4,
                rsvpStatus: .invited,
                lifecycleStatus: .scheduled,
                attendees: MockActivityAttendees.roster(
                    host: coffeeHost,
                    members: ["阿北", "西西", "Leo"]
                ),
                conversationThreadID: ActivityThreadID.make(for: "act_2")
            )
    }

    private static func runDetail(tomorrowMorning: Date) -> [ActivityDetail] {
        let runHost = String(
            localized: "activity.item.3.host",
            defaultValue: "Nova",
            comment: "Activity host"
        )

        return [
            ActivityDetail(
                id: "act_3",
                title: String(
                    localized: "activity.item.3.title",
                    defaultValue: "跑步打卡",
                    comment: "Activity item"
                ),
                summary: String(
                    localized: "activity.item.3.summary",
                    defaultValue: "5km · 滨江",
                    comment: "Activity summary"
                ),
                category: String(
                    localized: "activity.category.fitness",
                    defaultValue: "运动",
                    comment: "Activity category"
                ),
                description: String(
                    localized: "activity.item.3.description",
                    defaultValue: "滨江慢摇 5km，配速随意。跑完可一起拉伸。",
                    comment: "Activity description"
                ),
                startsAt: tomorrowMorning,
                locationName: String(
                    localized: "activity.item.3.location",
                    defaultValue: "滨江跑道入口",
                    comment: "Activity location"
                ),
                hostDisplayName: runHost,
                hostID: "host_run",
                hostBio: String(
                    localized: "activity.item.3.hostBio",
                    defaultValue: "滨江跑步打卡发起人。",
                    comment: "Host bio"
                ),
                attendeeCount: 3,
                capacity: nil,
                rsvpStatus: .host,
                lifecycleStatus: .scheduled,
                attendees: MockActivityAttendees.hostRoster(
                    host: runHost,
                    members: [
                        ("大K", .going),
                        ("小鱼", .maybe),
                        ("阿哲", .declined),
                        ("排队君", .waitlisted)
                    ]
                ),
                conversationThreadID: ActivityThreadID.make(for: "act_3")
            )
        ]
    }

    private static func endedAndBookClubDetails(lastWeek: Date, sundayAfternoon: Date) -> [ActivityDetail] {
        [boardGameDetail(startsAt: lastWeek), bookClubDetail(startsAt: sundayAfternoon)]
    }

    private static func boardGameDetail(startsAt: Date) -> ActivityDetail {
        ActivityDetail(
                id: "act_4",
                title: String(
                    localized: "activity.item.4.title",
                    defaultValue: "桌游夜",
                    comment: "Activity item"
                ),
                summary: String(
                    localized: "activity.item.4.summary",
                    defaultValue: "上周六 · 已结束",
                    comment: "Activity summary"
                ),
                category: String(
                    localized: "activity.category.social",
                    defaultValue: "社交",
                    comment: "Activity category"
                ),
                description: String(
                    localized: "activity.item.4.description",
                    defaultValue: "德式桌游入门局，规则现场讲解。",
                    comment: "Activity description"
                ),
                startsAt: startsAt,
                locationName: String(
                    localized: "activity.item.4.location",
                    defaultValue: "徐汇社区活动室",
                    comment: "Activity location"
                ),
                hostDisplayName: String(
                    localized: "activity.item.4.host",
                    defaultValue: "老周",
                    comment: "Activity host"
                ),
                hostID: "host_boardgame",
                hostBio: String(
                    localized: "activity.item.4.hostBio",
                    defaultValue: "社区桌游夜固定主办。",
                    comment: "Host bio"
                ),
                attendeeCount: 6,
                capacity: 8,
                rsvpStatus: .going,
                lifecycleStatus: .ended,
                attendees: MockActivityAttendees.roster(host: "老周", members: ["你", "Amy", "石头", "小鹿", "Han"]),
                conversationThreadID: ActivityThreadID.make(for: "act_4")
            )
    }

    private static func bookClubDetail(startsAt: Date) -> ActivityDetail {
        ActivityDetail(
                id: "act_5",
                title: String(
                    localized: "activity.item.5.title",
                    defaultValue: "读书分享局",
                    comment: "Activity item"
                ),
                summary: String(
                    localized: "activity.item.5.summary",
                    defaultValue: "周日午后 · 12 人小局",
                    comment: "Activity summary"
                ),
                category: String(
                    localized: "activity.category.social",
                    defaultValue: "社交",
                    comment: "Activity category"
                ),
                description: String(
                    localized: "activity.item.5.description",
                    defaultValue: "每人带一本最近在读的书，轮流分享 5 分钟。无推销，纯聊天。",
                    comment: "Activity description"
                ),
                startsAt: startsAt,
                locationName: String(
                    localized: "activity.item.5.location",
                    defaultValue: "浦东图书馆咖啡区",
                    comment: "Activity location"
                ),
                hostDisplayName: String(
                    localized: "activity.item.5.host",
                    defaultValue: "书虫阿宁",
                    comment: "Activity host"
                ),
                hostID: "host_book",
                hostBio: String(
                    localized: "activity.item.5.hostBio",
                    defaultValue: "每月办一次读书小局。",
                    comment: "Host bio"
                ),
                attendeeCount: 6,
                capacity: 12,
                rsvpStatus: .invited,
                lifecycleStatus: .scheduled,
                attendees: MockActivityAttendees.roster(
                    host: "书虫阿宁",
                    members: ["Luna", "老陈", "Momo", "Ken", "小满"]
                ),
                conversationThreadID: ActivityThreadID.make(for: "act_5")
            )
    }
}
