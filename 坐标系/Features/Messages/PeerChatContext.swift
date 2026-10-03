//
//  PeerChatContext.swift
//  坐标系
//
//  私聊入口上下文、路由与快捷回复文案。
//

import SwiftUI
import CoordinateModels

/// 从业务页进入私聊时的上下文（快捷模版 + 冷启动发送上限）。
enum ConversationChatContext: Hashable {
    case activityHost(activityID: Activity.ID)
    case activityMember(activityID: Activity.ID)
    /// 活动群聊（从详情 / 参加成功进群，不切消息 Tab）
    case activityGroup(activityID: Activity.ID)
    /// 俱乐部群聊（从俱乐部资料进群，不切消息 Tab）
    case clubGroup(circleID: InterestCircle.ID)
    case buddyFree(lookingFor: String, sharedHobbies: [String])
    case buddyPaid(specialty: String)
    case circleMember(circleName: String)
    case guildMember(guildName: String)
    case voiceHall(hallTitle: String)
    case bookingCompanion(scheduleLine: String)
    case inviteBuddy(activityTitle: String)
    case communityAuthor

    static let coldOutreachLimit = 3

    /// 已建立业务关系、可跳过好友门槛的场景。
    var bypassesFriendGate: Bool {
        switch self {
        case .bookingCompanion, .activityGroup, .activityHost, .activityMember, .clubGroup:
            true
        default:
            false
        }
    }

    var quickReplySectionTitle: String {
        switch self {
        case .activityHost:
            ActivityDetailCopy.askHostQuickRepliesTitle
        case .activityMember, .buddyFree, .buddyPaid, .circleMember, .guildMember, .voiceHall, .inviteBuddy, .communityAuthor:
            PeerChatCopy.greetingSectionTitle
        case .bookingCompanion:
            PeerChatCopy.bookingSectionTitle
        case .activityGroup, .clubGroup:
            PeerChatCopy.greetingSectionTitle
        }
    }

    @MainActor
    func quickReplies(
        peerName: String,
        activities: ActivitiesModel,
        currentUser: AppUser
    ) -> [(label: String, text: String)] {
        switch self {
        case .activityHost(let activityID):
            guard let activity = activities.activity(id: activityID) else { return [] }
            return ActivityDetailCopy.askHostQuickReplies(for: activity)
        case .activityMember(let activityID):
            guard let activity = activities.activity(id: activityID) else { return [] }
            return ActivityDetailCopy.askMemberQuickReplies(for: activity)
        case .activityGroup:
            return []
        case .clubGroup:
            return []
        case .buddyFree(let lookingFor, let sharedHobbies):
            return PeerChatCopy.buddyFreeReplies(lookingFor: lookingFor, sharedHobbies: sharedHobbies)
        case .buddyPaid(let specialty):
            return PeerChatCopy.buddyPaidReplies(specialty: specialty)
        case .circleMember(let circleName):
            return PeerChatCopy.circleMemberReplies(circleName: circleName)
        case .guildMember(let guildName):
            return PeerChatCopy.guildMemberReplies(guildName: guildName)
        case .voiceHall(let hallTitle):
            return PeerChatCopy.voiceHallReplies(hallTitle: hallTitle)
        case .bookingCompanion(let scheduleLine):
            return PeerChatCopy.bookingCompanionReplies(scheduleLine: scheduleLine)
        case .inviteBuddy(let activityTitle):
            return PeerChatCopy.inviteBuddyReplies(activityTitle: activityTitle)
        case .communityAuthor:
            return PeerChatCopy.communityAuthorReplies(peerName: peerName)
        }
    }

    @MainActor
    static func forBuddyItem(_ item: DiscoverBuddyItem) -> ConversationChatContext {
        switch item {
        case .free(let buddy):
            let shared = BuddyMatchScorer.sharedHobbies(with: buddy.profile)
            return .buddyFree(
                lookingFor: buddy.profile.lookingFor,
                sharedHobbies: shared
            )
        case .paid(let companion):
            return .buddyPaid(specialty: companion.specialty)
        }
    }

    @MainActor
    static func forMemberTarget(_ target: BuddyMemberProfileTarget) -> ConversationChatContext {
        switch target.source {
        case .discover:
            return forBuddyItem(target.item)
        case .circle(let name, _):
            return .circleMember(circleName: name)
        case .guild(let name, _):
            return .guildMember(guildName: name)
        case .voiceHall(let title, _):
            return .voiceHall(hallTitle: title)
        }
    }

    static func forBooking(_ record: BuddyBookingRecord) -> ConversationChatContext {
        .bookingCompanion(scheduleLine: PeerChatCopy.bookingScheduleLine(for: record))
    }
}

struct PeerChatRoute: Identifiable, Hashable {
    var id: ChatConversation.ID { conversationID }
    let conversationID: ChatConversation.ID
    let chatContext: ConversationChatContext
}

struct AddFriendPeerRoute: Identifiable, Hashable {
    let nickname: String
    let context: ConversationChatContext
    var isPending: Bool

    var id: String { nickname }
}

enum PeerContactRoute: Identifiable, Hashable {
    case chat(PeerChatRoute)
    case addFriend(AddFriendPeerRoute)

    var id: String {
        switch self {
        case .chat(let route):
            "chat-\(route.id)"
        case .addFriend(let route):
            "friend-\(route.id)-\(route.isPending)"
        }
    }
}

enum PeerChatCopy {
    static let greetingSectionTitle = "快捷打招呼"
    static let bookingSectionTitle = "快捷确认"
    static let outboundBlockedNotice = MessagesCopy.outboundBlockedNotice

    static func buddyFreeReplies(
        lookingFor: String,
        sharedHobbies: [String]
    ) -> [(label: String, text: String)] {
        var rows: [(String, String)] = []
        let looking = lookingFor.trimmingCharacters(in: .whitespacesAndNewlines)
        if !looking.isEmpty {
            rows.append(("一起 \(looking)", "你好，看到你想「\(looking)」，我也想一起，方便聊聊吗？"))
        }
        if !sharedHobbies.isEmpty {
            let hobbies = sharedHobbies.prefix(2).joined(separator: "、")
            rows.append(("共同兴趣", "你好，看到我们都喜欢\(hobbies)，想一起玩吗？"))
        }
        rows.append(("打个招呼", "你好，想认识你，方便聊聊吗？"))
        rows.append(("约时间", "你这周什么时候比较方便？"))
        return rows
    }

    static func buddyPaidReplies(specialty: String) -> [(label: String, text: String)] {
        [
            ("了解服务", "你好！我看到你提供「\(specialty)」，想了解一下。"),
            ("预约时间", "你好，想预约一下，你最近方便吗？"),
            ("费用咨询", "想了解一下价格和时长，方便介绍一下吗？"),
        ]
    }

    static func circleMemberReplies(circleName: String) -> [(label: String, text: String)] {
        [
            ("打个招呼", "你好，我在「\(circleName)」看到你，想认识一下。"),
            ("活动交流", "你好，请问你平时会参加俱乐部里的哪些活动？"),
            ("同行邀约", "最近有想一起玩的安排吗？"),
        ]
    }

    static func guildMemberReplies(guildName: String) -> [(label: String, text: String)] {
        [
            ("打个招呼", "你好，我在工会「\(guildName)」看到你，想了解一下。"),
            ("服务咨询", "你好，想了解一下你提供的服务内容。"),
            ("预约时间", "你这周什么时候比较方便？"),
        ]
    }

    static func voiceHallReplies(hallTitle: String) -> [(label: String, text: String)] {
        [
            ("打个招呼", "你好，我在「\(hallTitle)」听到你了～"),
            ("一起聊聊", "现在方便聊几句吗？"),
            ("交个朋友", "感觉聊得挺投缘，可以加个好友吗？"),
        ]
    }

    static func bookingScheduleLine(for record: BuddyBookingRecord) -> String {
        "\(Formatters.monthDay.string(from: record.scheduledAt)) "
            + "\(Formatters.shortTime.string(from: record.scheduledAt)) · \(record.hours) 小时"
    }

    static func bookingCompanionReplies(scheduleLine: String) -> [(label: String, text: String)] {
        [
            ("确认预约", "你好！我想预约 \(scheduleLine)，方便确认一下吗？"),
            ("改时间", "你好，想和你商量一下预约时间，方便吗？"),
            ("费用咨询", "想确认一下费用和时长，谢谢。"),
        ]
    }

    static func inviteBuddyReplies(activityTitle: String) -> [(label: String, text: String)] {
        [
            ("活动邀约", "你好，想邀请你一起参加「\(activityTitle)」，方便吗？"),
            ("打个招呼", "你好，想认识你，方便聊聊吗？"),
            ("确认时间", "这次活动你方便来吗？有问题可以直接问我。"),
        ]
    }

    static func communityAuthorReplies(peerName: String) -> [(label: String, text: String)] {
        [
            ("打个招呼", "你好，看了你在社区的内容，想认识一下。"),
            ("请教交流", "你好，对你分享的内容很感兴趣，方便聊聊吗？"),
        ]
    }
}
