//
//  PeerChatEntry.swift
//  坐标系
//
//  微信式私聊入口：已是好友才进会话；陌生人先加好友。预约履约等场景可例外直聊。
//

import SwiftUI

/// 从业务页进入私聊时的上下文（快捷模版 + 冷启动发送上限）。
enum ConversationChatContext: Hashable {
    case activityHost(activityID: Activity.ID)
    case activityMember(activityID: Activity.ID)
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
        case .bookingCompanion:
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
            ("活动交流", "你好，请问你平时会参加圈子里的哪些活动？"),
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

extension AppModel {
    func peerContactActionTitle(for nickname: String, context: ConversationChatContext) -> String {
        if messages.canStartDirectChat(with: nickname, context: context) {
            return MessagesCopy.friendSendMessage
        }
        if messages.hasPendingOutgoingFriendRequest(to: nickname) {
            return MessagesCopy.friendRequestPending
        }
        return MessagesCopy.addFriendAction
    }

    /// 已是好友（或场景允许）→ 进私聊；否则 → 加好友申请。
    @discardableResult
    func openPeerContact(with nickname: String, context: ConversationChatContext) -> PeerContactRoute? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }
        if blockedUserNames.contains(where: { $0.caseInsensitiveCompare(name) == .orderedSame }) {
            return nil
        }

        if messages.canStartDirectChat(with: name, context: context) {
            guard let convo = startDirectChat(with: name, greeting: "", deliverGreeting: false) else {
                return nil
            }
            return .chat(PeerChatRoute(conversationID: convo.id, chatContext: context))
        }

        let pending = messages.hasPendingOutgoingFriendRequest(to: name)
        return .addFriend(
            AddFriendPeerRoute(nickname: name, context: context, isPending: pending)
        )
    }

    /// 进入私聊，不自动发消息（仅好友或已放行场景使用）。
    @discardableResult
    func beginPeerChat(
        with nickname: String,
        context: ConversationChatContext
    ) -> PeerChatRoute? {
        guard let route = openPeerContact(with: nickname, context: context),
              case .chat(let chatRoute) = route
        else { return nil }
        return chatRoute
    }
}

extension MessagesModel {
    /// 对方是否曾在该会话中回复过（有则解除冷启动上限）。
    func hasPeerReply(in conversationID: ChatConversation.ID) -> Bool {
        guard let thread = threads[conversationID] else { return false }
        return thread.contains { !$0.isMe && !$0.isSystem }
    }
}

// MARK: - Add friend sheet

struct AddFriendPeerSheet: View {
    let route: AddFriendPeerRoute

    @Environment(MessagesModel.self) private var messages
    @Environment(ActivitiesModel.self) private var activities
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss

    @State private var verificationMessage = ""
    @State private var alertTitle: String?
    @State private var alertMessage: String?

    private var quickReplies: [(label: String, text: String)] {
        route.context.quickReplies(
            peerName: route.nickname,
            activities: activities,
            currentUser: app.user
        )
    }

    var body: some View {
        MessagesFormSheet(
            title: MessagesCopy.addFriendPeerTitle,
            dismissAction: .cancel
        ) {
            Form {
                Section {
                    HStack(spacing: PlatformMetrics.cardInfoSpacing) {
                        PlatformListAvatarView(name: route.nickname, side: 52)
                        Text(route.nickname)
                            .font(.headline)
                    }
                } footer: {
                    Text(MessagesCopy.addFriendVerifyFooter)
                }

                if route.isPending {
                    Section {
                        Label(
                            MessagesCopy.friendRequestPendingDescription,
                            systemImage: "clock"
                        )
                        .foregroundStyle(.secondary)
                    }
                } else {
                    Section {
                        TextField(
                            MessagesCopy.addFriendVerifyPlaceholder,
                            text: $verificationMessage,
                            axis: .vertical
                        )
                        .lineLimit(3...6)
                    } header: {
                        Text(MessagesCopy.addFriendVerifyField)
                    }

                    if !quickReplies.isEmpty {
                        Section(route.context.quickReplySectionTitle) {
                            ForEach(Array(quickReplies.enumerated()), id: \.offset) { _, reply in
                                Button(reply.label) {
                                    verificationMessage = reply.text
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                if !route.isPending {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(MessagesCopy.addFriendSend) {
                            submitRequest()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert(alertTitle ?? "", isPresented: Binding(
                get: { alertTitle != nil },
                set: { if !$0 { alertTitle = nil } }
            )) {
                Button("好的", role: .cancel) {
                    alertTitle = nil
                    dismiss()
                }
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    private func submitRequest() {
        switch messages.sendFriendRequest(to: route.nickname, message: verificationMessage) {
        case .sent:
            alertTitle = MessagesCopy.friendRequestSentTitle
            alertMessage = MessagesCopy.friendRequestSentMessage(route.nickname)
        case .alreadyFriend:
            alertTitle = MessagesCopy.addFriendPeerTitle
            alertMessage = MessagesCopy.addFriendAlreadyFriend(route.nickname)
        case .alreadyPending:
            alertTitle = MessagesCopy.friendRequestPending
            alertMessage = MessagesCopy.friendRequestPendingDescription
        case .invalidName:
            break
        }
    }
}

// MARK: - Navigation

extension View {
    func peerContactDestination(route: Binding<PeerContactRoute?>) -> some View {
        modifier(PeerContactDestinationModifier(route: route))
    }

    /// 仅聊天目的地（通讯录等已是好友的场景）。
    func peerChatNavigationDestination(route: Binding<PeerChatRoute?>) -> some View {
        navigationDestination(item: route) { route in
            ConversationDetailView(
                conversationID: route.conversationID,
                chatContext: route.chatContext
            )
            .toolbarVisibility(.hidden, for: .tabBar)
        }
    }
}

private struct PeerContactDestinationModifier: ViewModifier {
    @Binding var route: PeerContactRoute?

    private var chatRoute: Binding<PeerChatRoute?> {
        Binding(
            get: {
                if case .chat(let chatRoute) = route { return chatRoute }
                return nil
            },
            set: { newValue in
                if let newValue {
                    route = .chat(newValue)
                } else if case .chat = route {
                    route = nil
                }
            }
        )
    }

    private var addFriendRoute: Binding<AddFriendPeerRoute?> {
        Binding(
            get: {
                if case .addFriend(let addRoute) = route { return addRoute }
                return nil
            },
            set: { newValue in
                if let newValue {
                    route = .addFriend(newValue)
                } else if case .addFriend = route {
                    route = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .peerChatNavigationDestination(route: chatRoute)
            .sheet(item: addFriendRoute) { addRoute in
                AddFriendPeerSheet(route: addRoute)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
    }
}
