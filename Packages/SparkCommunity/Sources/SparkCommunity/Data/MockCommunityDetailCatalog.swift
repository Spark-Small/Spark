// Module: SparkCommunity — Mock community detail, members, and linked activities.

import Foundation

enum MockCommunityDetailCatalog {
    static func detail(id: String, joinedIDs: Set<String>? = nil) -> CommunityDetail? {
        guard let summary = MockCommunityTabCatalog.allCommunities().first(where: { $0.id == id })
            ?? MockCommunityTabCatalog.joinedCommunities().first(where: { $0.id == id })
        else { return nil }
        let defaultJoined = Set(MockCommunityTabCatalog.joinedCommunities().map(\.id))
        let joinedSet = joinedIDs ?? defaultJoined
        return CommunityDetail(summary: summary, isJoined: joinedSet.contains(id))
    }

    static func members(communityID: String) -> [CommunityMember] {
        switch communityID {
        case "cm_hike":
            return hikeMembers
        default:
            return Array(hikeMembers.prefix(2))
        }
    }

    private static let hikeMembers: [CommunityMember] = [
        CommunityMember(
            id: "u_host_1",
            displayName: String(localized: "community.mock.1.author", defaultValue: "阿乐", comment: "Author"),
            avatarURL: URL(string: "https://picsum.photos/seed/person-1/96/96"),
            bio: String(localized: "community.mock.member.bio.1", defaultValue: "周末爬山", comment: "Bio"),
            relationship: .sharedActivity(
                String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity")
            )
        ),
        CommunityMember(
            id: "u_host_2",
            displayName: String(localized: "community.mock.2.author", defaultValue: "小雨", comment: "Author"),
            avatarURL: URL(string: "https://picsum.photos/seed/person-2/96/96"),
            bio: String(localized: "community.mock.member.bio.2", defaultValue: "滨江跑步", comment: "Bio"),
            relationship: .liked
        ),
        CommunityMember(
            id: "u_guest_1",
            displayName: String(localized: "community.mock.person.3", defaultValue: "张伟", comment: "Person"),
            avatarURL: URL(string: "https://picsum.photos/seed/person-3/96/96"),
            bio: String(localized: "community.mock.member.bio.3", defaultValue: "摄影爱好者", comment: "Bio"),
            relationship: .none
        )
    ]

    static func activities(communityID: String) -> [CommunityLinkedActivity] {
        switch communityID {
        case "cm_hike":
            return [
                CommunityLinkedActivity(
                    id: "act_001",
                    title: String(localized: "community.mock.activity.hike", defaultValue: "周末爬香山", comment: "Activity"),
                    scheduleLine: String(localized: "community.mock.activity.schedule", defaultValue: "周六 9:30", comment: "Schedule")
                ),
                CommunityLinkedActivity(
                    id: "act_002",
                    title: String(localized: "community.mock.activity.trail", defaultValue: "城郊步道", comment: "Activity"),
                    scheduleLine: String(localized: "community.mock.activity.schedule2", defaultValue: "下周日 8:00", comment: "Schedule")
                )
            ]
        case "cm_book":
            return [
                CommunityLinkedActivity(
                    id: "act_003",
                    title: String(localized: "community.mock.activity.book", defaultValue: "咖啡聊天局", comment: "Activity"),
                    scheduleLine: String(localized: "community.mock.activity.schedule3", defaultValue: "周五 19:00", comment: "Schedule")
                )
            ]
        default:
            return []
        }
    }

    static func posts(communityID: String) -> [CommunityFeedPost] {
        MockCommunityTabCatalog.feedPosts().filter { post in
            post.communityName == detail(id: communityID)?.summary.name
        }
    }
}
