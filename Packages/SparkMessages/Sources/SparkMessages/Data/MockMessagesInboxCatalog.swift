// Module: SparkMessages — Rich mock unified inbox for previews and tests.

import Foundation

enum MockMessagesInboxCatalog {
    static func inbox(unreadCount: Int) -> MessagesInbox {
        let now = Date()
        let activities = sampleActivities(now: now)
        return MessagesInbox(
            actionItems: sampleActionItems(now: now, activities: activities),
            unmessagedMatches: sampleMatches(now: now),
            dmConversations: sampleDMConversations(now: now, unreadCount: unreadCount),
            activeGroupChats: sampleActiveGroups(now: now, unreadCount: unreadCount),
            archivedGroupChats: sampleArchivedGroups(now: now, endedActivity: activities.ended)
        )
    }

    static func conversationContext(for threadID: MessageThreadID) -> ConversationContext {
        if threadID.rawValue.hasPrefix("th_dm_") {
            return ConversationContext(
                sharedActivities: [
                    InboxActivitySummary(
                        id: "act_1",
                        title: String(localized: "messages.mock.hike.title", defaultValue: "周末爬香山", comment: "Hike"),
                        startsAt: Date().addingTimeInterval(86_400 * 2),
                        attendeeCount: 12
                    )
                ],
                relationshipStatus: "matched"
            )
        }
        return ConversationContext(sharedActivities: [], relationshipStatus: "none")
    }

    private struct SampleActivities {
        let hike: InboxActivitySummary
        let ride: InboxActivitySummary
        let ended: InboxActivitySummary
    }

    private static func sampleActivities(now: Date) -> SampleActivities {
        SampleActivities(
            hike: InboxActivitySummary(
                id: "act_2",
                title: String(localized: "messages.mock.hike.title", defaultValue: "周末爬香山", comment: "Hike"),
                coverURL: URL(string: "https://picsum.photos/seed/hike/96/96"),
                startsAt: now.addingTimeInterval(86_400 * 2),
                attendeeCount: 12
            ),
            ride: InboxActivitySummary(
                id: "act_4",
                title: String(localized: "messages.mock.ride.title", defaultValue: "周末骑行", comment: "Ride"),
                coverURL: URL(string: "https://picsum.photos/seed/ride/96/96"),
                startsAt: now.addingTimeInterval(86_400 * 7),
                attendeeCount: 8
            ),
            ended: InboxActivitySummary(
                id: "act_9",
                title: String(localized: "messages.mock.past.title", defaultValue: "上周读书会", comment: "Past event"),
                coverURL: URL(string: "https://picsum.photos/seed/book/96/96"),
                startsAt: now.addingTimeInterval(-86_400 * 5),
                attendeeCount: 6,
                lifecycle: .ended
            )
        )
    }

    private static func sampleActionItems(now: Date, activities: SampleActivities) -> [ActionItem] {
        [
            ActionItem(
                id: "action_waitlist_1",
                kind: .waitlistPromoted(activities.hike),
                priority: 0,
                createdAt: now.addingTimeInterval(-120)
            ),
            ActionItem(
                id: "action_change_1",
                kind: .activityChanged(
                    ActivityChange(
                        id: "change_1",
                        kind: .rescheduled,
                        activity: activities.ride,
                        hostName: String(localized: "messages.mock.host.li", defaultValue: "李明", comment: "Host"),
                        previousScheduleLine: String(
                            localized: "messages.mock.prev.sat",
                            defaultValue: "原定本周六",
                            comment: "Previous schedule"
                        )
                    )
                ),
                priority: 1,
                createdAt: now.addingTimeInterval(-600)
            ),
            ActionItem(
                id: "action_invite_1",
                kind: .activityInvite(
                    ActivityInvite(
                        id: "inv_1",
                        activity: activities.hike,
                        inviter: InboxUserProfile(
                            id: "u_wang",
                            displayName: String(localized: "messages.mock.wang", defaultValue: "王芳", comment: "Inviter"),
                            avatarURL: URL(string: "https://picsum.photos/seed/wang/96/96")
                        )
                    )
                ),
                priority: 2,
                createdAt: now.addingTimeInterval(-1800)
            )
        ]
    }

    private static func sampleMatches(now: Date) -> [MatchPreview] {
        [
            MatchPreview(
                id: "match_1",
                user: InboxUserProfile(
                    id: "u_li",
                    displayName: String(localized: "messages.mock.li", defaultValue: "李明", comment: "Match"),
                    avatarURL: URL(string: "https://picsum.photos/seed/li/96/96")
                ),
                matchedAt: now.addingTimeInterval(-3600)
            ),
            MatchPreview(
                id: "match_2",
                user: InboxUserProfile(
                    id: "u_wang",
                    displayName: String(localized: "messages.mock.wang", defaultValue: "王芳", comment: "Match"),
                    avatarURL: URL(string: "https://picsum.photos/seed/wang/96/96")
                ),
                matchedAt: now.addingTimeInterval(-7200)
            )
        ]
    }

    private static func sampleDMConversations(now: Date, unreadCount: Int) -> [ConversationPreview] {
        [
            ConversationPreview(
                threadID: MessageThreadID("th_dm_u_ale"),
                kind: .dm,
                displayName: String(localized: "messages.mock.ale", defaultValue: "阿乐", comment: "DM"),
                lastMessagePreview: String(
                    localized: "messages.mock.dm.preview",
                    defaultValue: "周六一起爬山吗？",
                    comment: "DM preview"
                ),
                lastMessageAt: now.addingTimeInterval(-900),
                unreadCount: max(1, unreadCount),
                dmPartner: InboxUserProfile(
                    id: "u_ale",
                    displayName: String(localized: "messages.mock.ale", defaultValue: "阿乐", comment: "DM"),
                    avatarURL: URL(string: "https://picsum.photos/seed/ale/96/96")
                ),
                isPartnerOnline: true
            )
        ]
    }

    private static func sampleActiveGroups(now: Date, unreadCount: Int) -> [ConversationPreview] {
        [
            ConversationPreview(
                threadID: MessageThreadID("th_activity_act_1"),
                kind: .groupChat,
                displayName: String(
                    localized: "activity.groupChat.hike.name",
                    defaultValue: "周末徒步 · 群",
                    comment: "Group"
                ),
                lastMessagePreview: String(
                    localized: "activity.groupChat.hike.preview",
                    defaultValue: "周六 9:30 北门集合",
                    comment: "Preview"
                ),
                lastMessageAt: now.addingTimeInterval(-300),
                unreadCount: unreadCount > 0 ? 1 : 0,
                activity: InboxActivitySummary(
                    id: "act_1",
                    title: String(localized: "activity.groupChat.hike.name", defaultValue: "周末徒步 · 群", comment: "Group"),
                    coverURL: URL(string: "https://picsum.photos/seed/hike-group/96/96"),
                    startsAt: now.addingTimeInterval(86_400),
                    attendeeCount: 9
                ),
                memberCount: 9
            ),
            ConversationPreview(
                threadID: MessageThreadID("th_activity_act_3"),
                kind: .groupChat,
                displayName: String(
                    localized: "activity.groupChat.run.name",
                    defaultValue: "跑步打卡 · 群",
                    comment: "Group"
                ),
                lastMessagePreview: String(
                    localized: "activity.groupChat.run.preview",
                    defaultValue: "明早 7:00 滨江入口见",
                    comment: "Preview"
                ),
                lastMessageAt: now.addingTimeInterval(-3600),
                unreadCount: 0,
                activity: InboxActivitySummary(
                    id: "act_3",
                    title: String(localized: "activity.groupChat.run.name", defaultValue: "跑步打卡 · 群", comment: "Group"),
                    coverURL: URL(string: "https://picsum.photos/seed/run-group/96/96"),
                    startsAt: now.addingTimeInterval(43_200),
                    attendeeCount: 5
                ),
                memberCount: 5
            )
        ]
    }

    private static func sampleArchivedGroups(now: Date, endedActivity: InboxActivitySummary) -> [ConversationPreview] {
        [
            ConversationPreview(
                threadID: MessageThreadID("th_activity_act_9"),
                kind: .groupChat,
                displayName: endedActivity.title,
                lastMessagePreview: String(
                    localized: "messages.mock.archived.preview",
                    defaultValue: "活动已结束，感谢参与",
                    comment: "Archived preview"
                ),
                lastMessageAt: now.addingTimeInterval(-86_400 * 4),
                unreadCount: 0,
                activity: endedActivity,
                memberCount: 6,
                isArchived: true
            )
        ]
    }
}
