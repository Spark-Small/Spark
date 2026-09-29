//
//  MessagesModel.swift
//  坐标系
//
//  会话商店：对齐 FoundationChat 式「列表 ↔ 详情」共享状态
//

import CoordinateDomain
import CoordinateModels
import CoordinateNetworking
import Foundation
import Observation

@MainActor
@Observable
final class MessagesModel {
    var searchText = ""
    var conversationPendingDelete: ChatConversation?
    /// 当前打开的会话详情：入站消息不增加未读
    var activeConversationID: ChatConversation.ID?
    var onConversationsChanged: (() -> Void)?

    var conversations: [ChatConversation]
    var friendRequests: [FriendRequest]
    var outgoingFriendRequests: [OutgoingFriendRequest]
    /// 昵称（小写）→ 备注
    var friendRemarks: [String: String]
    /// 昵称（小写）→ 好友分组
    var friendGroups: [String: String]
    var groupMembersByConversation: [UUID: [GroupMemberRecord]]
    var transferRecords: [TransferRecord]
    var callRecords: [CallSessionRecord]
    var threads: [UUID: [ChatMessage]]
    let repository: any MessagesRepository
    let callingService: any CallingService
    let transferService: any TransferService
    let groupAdminService: any GroupAdminService
    let messageRequestService: any MessageRequestService
    @ObservationIgnored var persistenceGeneration: Int
    @ObservationIgnored var persistTask: Task<Void, Never>?
    @ObservationIgnored var transferExpirationTasks: [TransferRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var autoReplyTasks: [ChatConversation.ID: Task<Void, Never>] = [:]
    @ObservationIgnored var readReceiptTasks: [ChatMessage.ID: Task<Void, Never>] = [:]
    /// 会话详情分页窗口（条数）；默认见 `MessagingDeliveryPolicy.pageSize`。
    @ObservationIgnored var messagePageLimitByConversation: [ChatConversation.ID: Int] = [:]
    @ObservationIgnored let walletStore: WalletStore

    init(
        snapshot: MessagesSnapshot? = nil,
        repository: any MessagesRepository,
        walletStore: WalletStore,
        callingService: (any CallingService)? = nil,
        transferService: (any TransferService)? = nil,
        groupAdminService: (any GroupAdminService)? = nil,
        messageRequestService: (any MessageRequestService)? = nil
    ) {
        self.repository = repository
        self.walletStore = walletStore
        self.callingService = callingService ?? LocalCallingService()
        self.transferService = transferService ?? LocalTransferService()
        self.groupAdminService = groupAdminService ?? LocalGroupAdminService()
        self.messageRequestService = messageRequestService ?? LocalMessageRequestService()
        persistenceGeneration = repository.currentPersistenceGeneration()
        let resolved = snapshot ?? repository.load()
        conversations = resolved.conversations
        friendRequests = resolved.friendRequests
        outgoingFriendRequests = resolved.outgoingFriendRequests
        friendRemarks = resolved.friendRemarks
        friendGroups = resolved.friendGroups
        groupMembersByConversation = Dictionary(
            uniqueKeysWithValues: resolved.groupMembers.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        transferRecords = resolved.transferRecords
        callRecords = resolved.callRecords
        threads = Dictionary(
            uniqueKeysWithValues: resolved.threads.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        bootstrapGroupMembersIfNeeded()
        normalizeMessageRequests()
        reconcileInboxPreviews()
        refreshTransferExpirations()
    }

    /// Tab 角标：非静音、非「消息请求」的收件箱未读合计（申请走通讯录角标）
    var unreadTotal: Int {
        conversations
            .filter { !$0.isMuted && !$0.isMessageRequest }
            .reduce(0) { $0 + $1.unreadCount }
    }

    /// 收件箱：好友会话与群聊合在同一列表
    var items: [ChatConversation] {
        conversations
            .filter { !$0.isMessageRequest }
            .sorted { lhs, rhs in
                let leftRank = Self.inboxSortRank(lhs)
                let rightRank = Self.inboxSortRank(rhs)
                if leftRank != rightRank { return leftRank < rightRank }
                if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
                return lhs.updatedAt > rhs.updatedAt
            }
    }

    /// 收件箱搜索：匹配好友 / 群聊会话
    func matchingConversations(query: String, blockedNames: [String]) -> [ChatConversation] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return conversations
            .filter { !$0.isMessageRequest }
            .filter { conversation in
                guard conversation.isFriendChat else { return true }
                return !blockedNames.contains {
                    $0.caseInsensitiveCompare(conversation.title) == .orderedSame
                }
            }
            .filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.lastMessage.localizedCaseInsensitiveContains(trimmed)
                    || $0.subtitle.localizedCaseInsensitiveContains(trimmed)
                    || $0.inboxPreview.localizedCaseInsensitiveContains(trimmed)
            }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func hasSearchResults(blockedNames: [String]) -> Bool {
        guard isSearching else { return false }
        return !matchingConversations(query: searchText, blockedNames: blockedNames).isEmpty
            || !searchHistory(query: searchText).isEmpty
    }

    func existingGroupChat(for activity: Activity) -> ChatConversation? {
        conversations.first {
            $0.kind == .activity && (
                $0.relatedActivityID == activity.id
                    || ($0.relatedActivityID == nil && $0.title == activity.title)
            )
        }
    }

    /// 收件箱排序：未读 → 在线 → 无状态点
    static func inboxSortRank(_ conversation: ChatConversation) -> Int {
        if conversation.unreadCount > 0 { return 0 }
        if conversation.kind == .direct, conversation.peerIsActive { return 1 }
        return 2
    }

    var messageRequests: [ChatConversation] {
        conversations
            .filter(\.isMessageRequest)
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    var pendingFriendRequestCount: Int {
        friendRequests.filter { $0.status == .pending }.count + messageRequests.count
    }

    var requestBadgeCount: Int {
        friendRequests.filter { $0.status == .pending }.count + pendingMessageRequests.count
    }

    var pendingMessageRequests: [ChatConversation] {
        messageRequests
    }

    var isEmptyInbox: Bool {
        conversations.filter { !$0.isMessageRequest }.isEmpty
    }

    func messages(for id: ChatConversation.ID) -> [ChatMessage] {
        threads[id] ?? []
    }

    func markRead(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].unreadCount = 0
        persist()
    }

    func toggleUnread(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].unreadCount = conversations[index].unreadCount > 0 ? 0 : 1
        persist()
    }

    func togglePin(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].isPinned.toggle()
        persist()
    }

    func toggleMute(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].isMuted.toggle()
        persist()
    }

    func requestDelete(_ conversation: ChatConversation) {
        conversationPendingDelete = conversation
    }

    func confirmDelete() {
        guard let conversation = conversationPendingDelete else { return }
        delete(conversation.id)
        conversationPendingDelete = nil
    }

    func cancelDelete() {
        conversationPendingDelete = nil
    }

    func delete(_ id: ChatConversation.ID) {
        conversations.removeAll { $0.id == id }
        threads[id] = nil
        groupMembersByConversation[id] = nil
        let transferIDs = transferRecords.filter { $0.conversationID == id }.map(\.id)
        for transferID in transferIDs {
            cancelTransferExpiration(for: transferID)
        }
        transferRecords.removeAll { $0.conversationID == id }
        callRecords.removeAll { $0.conversationID == id }
        persist()
        onConversationsChanged?()
    }

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

enum GroupChatJoinRole: Equatable {
    /// 发布活动创建群
    case host
    /// 报名加入群
    case participant
}
