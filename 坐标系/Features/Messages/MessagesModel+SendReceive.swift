//
//  MessagesModel+SendReceive.swift
//  坐标系
//
//  收发 / 重试 / 已读回执 / 演示自动回复。
//

import CoordinateDomain
import CoordinateModels
import CoordinateNetworking
import Foundation
import Observation

extension MessagesModel {
    /// 发送消息并回写收件箱预览（商用会话的基本闭环）
    @discardableResult
    func send(
        text: String,
        to id: ChatConversation.ID,
        replyingTo: ChatMessage? = nil
    ) -> ChatMessage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, index(of: id) != nil else { return nil }
        if case .block = ContentModeration.scanText(trimmed) {
            return nil
        }

        let initialStatus = Self.outboundDeliveryStatus()
        let message = ChatMessage(
            id: UUID(),
            sender: "我",
            text: trimmed,
            sentAt: .now,
            isMe: true,
            replyToSender: replyingTo.map { $0.isMe ? "我" : $0.sender },
            replyToText: replyingTo?.text,
            deliveryStatus: initialStatus
        )
        appendMessage(message, to: id)
        if initialStatus != .failed {
            if MessagingDeliveryPolicy.simulatesLocalReadReceipt {
                scheduleReadReceipt(for: message.id, in: id)
            }
            if MessagingDeliveryPolicy.simulatesPeerAutoReply {
                scheduleDemoAutoReply(to: id)
            }
        }
        return message
    }

    @discardableResult
    func sendPayload(_ message: ChatMessage, to id: ChatConversation.ID) -> ChatMessage? {
        guard index(of: id) != nil else { return nil }
        var outbound = message
        if MessagingDeliveryPolicy.failsSendWhenOffline, !APINetworkReachability.shared.isSatisfied {
            outbound.deliveryStatus = .failed
        } else if MessagingDeliveryPolicy.upgradesLocalSendToDelivered {
            if outbound.deliveryStatus == .sent {
                outbound.deliveryStatus = .delivered
            }
        } else if outbound.deliveryStatus == .delivered || outbound.deliveryStatus == .read {
            // Release：本机落盘不得冒充已送达 / 已读。
            outbound.deliveryStatus = .sent
        }
        appendMessage(outbound, to: id)
        if outbound.isMe, outbound.deliveryStatus != .failed {
            if MessagingDeliveryPolicy.simulatesLocalReadReceipt {
                scheduleReadReceipt(for: outbound.id, in: id)
            }
            if MessagingDeliveryPolicy.simulatesPeerAutoReply {
                scheduleDemoAutoReply(to: id)
            }
        }
        return outbound
    }

    /// 将本地消息标为发送失败（远程 IM 失败或内容审核拒绝时调用）。
    func markSendFailed(messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard var list = threads[conversationID],
              let idx = list.firstIndex(where: { $0.id == messageID && $0.isMe })
        else { return }
        list[idx].deliveryStatus = .failed
        threads[conversationID] = list
        persist()
    }

    /// 重发失败消息：重置为已发送并重新走本地发送后处理。
    @discardableResult
    func retrySend(messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) -> ChatMessage? {
        guard var list = threads[conversationID],
              let idx = list.firstIndex(where: {
                  $0.id == messageID && $0.isMe && $0.deliveryStatus == .failed
              })
        else { return nil }
        list[idx].deliveryStatus =
            MessagingDeliveryPolicy.upgradesLocalSendToDelivered ? .delivered : .sent
        if MessagingDeliveryPolicy.failsSendWhenOffline, !APINetworkReachability.shared.isSatisfied {
            list[idx].deliveryStatus = .failed
        }
        list[idx].sentAt = .now
        threads[conversationID] = list
        if let index = index(of: conversationID) {
            conversations[index].lastMessage = list[idx].previewText
            conversations[index].lastMessageIsMe = true
            conversations[index].updatedAt = list[idx].sentAt
            conversations[index].unreadCount = 0
        }
        persist()
        guard list[idx].deliveryStatus != .failed else { return list[idx] }
        if MessagingDeliveryPolicy.simulatesLocalReadReceipt {
            scheduleReadReceipt(for: messageID, in: conversationID)
        }
        if MessagingDeliveryPolicy.simulatesPeerAutoReply {
            scheduleDemoAutoReply(to: conversationID)
        }
        return list[idx]
    }

    /// Release 离线标失败；DEBUG 可本地「已发送 / 已送达」。
    private static func outboundDeliveryStatus() -> ChatDeliveryStatus {
        if MessagingDeliveryPolicy.failsSendWhenOffline, !APINetworkReachability.shared.isSatisfied {
            return .failed
        }
        return MessagingDeliveryPolicy.upgradesLocalSendToDelivered ? .delivered : .sent
    }

    /// 入站消息：更新预览、未读；可选本地通知
    @discardableResult
    func receive(
        _ message: ChatMessage,
        to id: ChatConversation.ID,
        notify: Bool = true
    ) -> ChatMessage? {
        guard let index = index(of: id) else { return nil }
        var inbound = message
        inbound.isMe = false
        if inbound.deliveryStatus == .sent {
            inbound.deliveryStatus = .delivered
        }
        appendMessage(inbound, to: id)
        if notify,
           activeConversationID != id,
           !conversations[index].isMuted {
            NotificationService.scheduleMessageNotification(
                conversationID: id,
                title: conversations[index].title,
                body: inbound.previewText
            )
        }
        return inbound
    }

    func appendMessage(_ message: ChatMessage, to id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        threads[id, default: []].append(message)
        conversations[index].lastMessage = message.previewText
        conversations[index].lastMessageIsMe = message.isMe
        conversations[index].updatedAt = message.sentAt
        if message.isMe {
            conversations[index].unreadCount = 0
        } else if activeConversationID != id {
            conversations[index].unreadCount += 1
        } else {
            conversations[index].unreadCount = 0
        }
        persist()
    }

    /// 本地演示：好友私聊发出后模拟对方回复（仅 `MessagingDeliveryPolicy` 允许时）。
    func scheduleDemoAutoReply(to id: ChatConversation.ID) {
        guard MessagingDeliveryPolicy.simulatesPeerAutoReply else { return }
        guard let conversation = conversations.first(where: { $0.id == id }),
              conversation.kind == .direct,
              !conversation.isMessageRequest
        else { return }

        let peer = conversation.title
        autoReplyTasks[id]?.cancel()
        autoReplyTasks[id] = Task { @MainActor in
            defer { autoReplyTasks[id] = nil }
            try? await Task.sleep(for: .milliseconds(1100))
            guard !Task.isCancelled,
                  let latest = threads[id]?.last,
                  latest.isMe
            else { return }
            let replies = MessagesCopy.demoAutoReplies
            _ = receive(
                ChatMessage(
                    id: UUID(),
                    sender: peer,
                    text: replies.randomElement() ?? replies[0],
                    sentAt: .now,
                    isMe: false
                ),
                to: id
            )
        }
    }

    func scheduleReadReceipt(for messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard MessagingDeliveryPolicy.simulatesLocalReadReceipt else { return }
        readReceiptTasks[messageID]?.cancel()
        readReceiptTasks[messageID] = Task { @MainActor in
            defer { readReceiptTasks[messageID] = nil }
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled,
                  var list = threads[conversationID],
                  let idx = list.firstIndex(where: { $0.id == messageID })
            else { return }
            list[idx].deliveryStatus = .read
            threads[conversationID] = list
            persist()
        }
    }

    func toggleLike(messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard var list = threads[conversationID],
              let index = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[index].isLiked.toggle()
        threads[conversationID] = list
        persist()
    }

    func deleteMessage(messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard var list = threads[conversationID] else { return }
        list.removeAll { $0.id == messageID }
        threads[conversationID] = list
        if let index = index(of: conversationID) {
            if let last = list.last {
                conversations[index].lastMessage = last.previewText
                conversations[index].lastMessageIsMe = last.isMe
                conversations[index].updatedAt = last.sentAt
            } else {
                conversations[index].lastMessage = ""
                conversations[index].lastMessageIsMe = false
            }
        }
        persist()
    }

    func markAllRead() {
        for index in conversations.indices {
            conversations[index].unreadCount = 0
        }
        persist()
    }
}
