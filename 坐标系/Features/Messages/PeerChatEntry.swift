//
//  PeerChatEntry.swift
//  坐标系
//
//  私聊入口：AppModel / MessagesModel 扩展与导航目的地。
//

import SwiftUI
import CoordinateModels

extension AppModel {
    func peerContactActionTitle(for nickname: String, context: ConversationChatContext) -> String {
        switch context {
        case .activityHost:
            return ActivityDetailCopy.askHostAction
        case .activityMember:
            return MessagesCopy.friendSendMessage
        default:
            break
        }
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
        guard requireIdentityAccess(source: .messaging) else { return nil }
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
// MARK: - Navigation

extension TabNavigationState {
    /// 活动栈已注册 `PeerChatRoute` 时：私聊走 path，加好友仍交给 sheet binding。
    func presentPeerContact(
        _ route: PeerContactRoute?,
        addFriend: (PeerContactRoute) -> Void
    ) {
        guard let route else { return }
        switch route {
        case .chat(let chat):
            path.append(chat)
        case .addFriend:
            addFriend(route)
        }
    }

    /// 俱乐部栈内打开俱乐部群聊
    func openClubGroupChat(for circle: InterestCircle, route: PeerChatRoute) {
        path.append(route)
    }

    /// 活动栈内打开群聊；栈空时先 Zoom 进详情，转场结束后再 push 群聊。
    func openActivityGroupChat(for activity: Activity, route: PeerChatRoute) {
        if path.isEmpty {
            path.append(ActivityZoomSource(activityID: activity.id, slot: "group-entry"))
            Task { @MainActor in
                try? await Task.sleep(for: ActivityZoomEngagement.postTransitionDelay)
                guard !Task.isCancelled else { return }
                path.append(route)
            }
        } else {
            path.append(route)
        }
    }
}

extension View {
    func peerContactDestination(route: Binding<PeerContactRoute?>) -> some View {
        modifier(PeerContactDestinationModifier(route: route))
    }

    /// 仅聊天目的地（Sheet 自有栈等未注册活动栈目的地的场景）。
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
    @Environment(\.hasActivityPeerChatDestination) private var activityStackHandlesPeerChat
    @Environment(\.hasCirclePeerChatDestination) private var circleStackHandlesPeerChat
    @Environment(\.tabNavigationStateRef) private var navigationRef

    /// 活动 / 搭子栈已注册 `PeerChatRoute` 时走 `NavigationPath`，避免 item 推栈藏 Tab 后 Zoom/侧滑返回不恢复。
    private var usesPathForChat: Bool {
        (activityStackHandlesPeerChat || circleStackHandlesPeerChat) && navigationRef != nil
    }

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
            .modifier(ConditionalPeerChatNavigation(route: chatRoute, enabled: !usesPathForChat))
            .onChange(of: route) { _, newRoute in
                guard usesPathForChat, let navigation = navigationRef else { return }
                guard case .chat(let chat) = newRoute else { return }
                route = nil
                navigation.path.append(chat)
            }
            .sheet(item: addFriendRoute) { addRoute in
                AddFriendPeerSheet(route: addRoute)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
    }
}

private struct ConditionalPeerChatNavigation: ViewModifier {
    @Binding var route: PeerChatRoute?
    let enabled: Bool

    func body(content: Content) -> some View {
        if enabled {
            content.peerChatNavigationDestination(route: $route)
        } else {
            content
        }
    }
}
