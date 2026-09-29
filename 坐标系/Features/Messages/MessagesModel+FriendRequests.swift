//
//  MessagesModel+FriendRequests.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    func acceptMessageRequest(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].isMessageRequest = false
        conversations[index].isFriend = true
        conversations[index].requestSource = nil
        conversations[index].requestPreviewText = nil
        conversations[index].unreadCount = 0
        persist()
    }

    func declineMessageRequest(_ id: ChatConversation.ID) {
        delete(id)
    }

    func acceptFriendRequest(_ id: FriendRequest.ID) {
        guard let idx = friendRequests.firstIndex(where: { $0.id == id }) else { return }
        friendRequests[idx].status = .accepted
        let name = friendRequests[idx].fromName
        let message = friendRequests[idx].message
        outgoingFriendRequests.removeAll {
            $0.toName.caseInsensitiveCompare(name) == .orderedSame
        }

        // 去掉同名消息请求，避免双入口
        for request in messageRequests where request.title.caseInsensitiveCompare(name) == .orderedSame {
            delete(request.id)
        }

        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if let cidx = index(of: existing.id) {
                conversations[cidx].isMessageRequest = false
                conversations[cidx].isFriend = true
                // 不伪造在线；真实在线状态由 IM 下发。
                conversations[cidx].peerIsActive = false
            }
            let alreadyHasPeerGreeting = threads[existing.id]?.contains {
                !$0.isMe && $0.text == message
            } ?? false
            if !alreadyHasPeerGreeting, !message.isEmpty {
                _ = receive(
                    ChatMessage(id: UUID(), sender: name, text: message, sentAt: .now, isMe: false),
                    to: existing.id,
                    notify: false
                )
            }
            if let cidx = index(of: existing.id) {
                conversations[cidx].unreadCount = 0
            }
        } else {
            let chatID = UUID()
            let conversation = ChatConversation(
                id: chatID,
                title: name,
                subtitle: MessagesCopy.friendSubtitle,
                lastMessage: message,
                updatedAt: .now,
                unreadCount: 0,
                kind: .direct,
                lastMessageIsMe: false,
                peerIsActive: false,
                isFriend: true
            )
            conversations.insert(conversation, at: 0)
            threads[chatID] = [
                ChatMessage(id: UUID(), sender: name, text: message, sentAt: .now, isMe: false)
            ]
        }
        persist()
    }

    enum AddFriendByUIDResult: Equatable {
        case requestSent(nickname: String, uid: String)
        case alreadyFriend(nickname: String)
        case alreadyPending(nickname: String)
        case isSelf
        case notFound
        case invalid
    }

    func isDirectFriend(with nickname: String) -> Bool {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return conversations.contains {
            $0.kind == .direct
                && !$0.isMessageRequest
                && $0.isFriend
                && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    func canStartDirectChat(with nickname: String, context: ConversationChatContext) -> Bool {
        if context.bypassesFriendGate { return true }
        return isDirectFriend(with: nickname)
    }

    func hasPendingOutgoingFriendRequest(to nickname: String) -> Bool {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        return outgoingFriendRequests.contains {
            $0.status == .pending && $0.toName.caseInsensitiveCompare(name) == .orderedSame
        }
    }

    enum SendFriendRequestResult: Equatable {
        case sent
        case alreadyFriend
        case alreadyPending
        case invalidName
    }

    @discardableResult
    func sendFriendRequest(to nickname: String, message: String) -> SendFriendRequestResult {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return .invalidName }
        if isDirectFriend(with: name) { return .alreadyFriend }
        if hasPendingOutgoingFriendRequest(to: name) { return .alreadyPending }

        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = trimmed.isEmpty ? MessagesCopy.defaultFriendRequestMessage : trimmed
        outgoingFriendRequests.insert(
            OutgoingFriendRequest(toName: name, message: body),
            at: 0
        )
        persist()
        onConversationsChanged?()
        return .sent
    }

    /// 通过对外数字 UID 发起好友申请（本地演示：走正常验证流程）。
    @discardableResult
    func addFriendByPublicUID(_ raw: String, myUser: AppUser) -> AddFriendByUIDResult {
        let normalized = UserPublicID.normalize(raw)
        guard UserPublicID.isValid(normalized) else { return .invalid }
        guard let hit = UserPublicDirectory.resolve(rawUID: normalized, myUser: myUser) else {
            return .notFound
        }
        if hit.isSelf { return .isSelf }
        if isDirectFriend(with: hit.nickname) {
            return .alreadyFriend(nickname: hit.nickname)
        }
        if hasPendingOutgoingFriendRequest(to: hit.nickname) {
            return .alreadyPending(nickname: hit.nickname)
        }

        let greeting = MessagesCopy.addFriendByUIDGreeting(uid: hit.uid)
        switch sendFriendRequest(to: hit.nickname, message: greeting) {
        case .sent:
            return .requestSent(nickname: hit.nickname, uid: hit.uid)
        case .alreadyFriend:
            return .alreadyFriend(nickname: hit.nickname)
        case .alreadyPending:
            return .alreadyPending(nickname: hit.nickname)
        case .invalidName:
            return .invalid
        }
    }
}
