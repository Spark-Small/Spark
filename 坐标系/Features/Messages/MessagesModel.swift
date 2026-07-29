//
//  MessagesModel.swift
//  坐标系
//
//  会话商店：对齐 FoundationChat 式「列表 ↔ 详情」共享状态
//

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

    private(set) var conversations: [ChatConversation]
    private(set) var friendRequests: [FriendRequest]
    /// 昵称（小写）→ 备注
    private(set) var friendRemarks: [String: String]
    /// 昵称（小写）→ 好友分组
    private(set) var friendGroups: [String: String]
    private(set) var groupMembersByConversation: [UUID: [GroupMemberRecord]]
    private(set) var transferRecords: [TransferRecord]
    private(set) var callRecords: [CallSessionRecord]
    var threads: [UUID: [ChatMessage]]
    private let repository: MessagesRepository
    private let callingService: any CallingService
    private let transferService: any TransferService
    private let groupAdminService: any GroupAdminService
    private let messageRequestService: any MessageRequestService
    @ObservationIgnored private var persistenceGeneration: Int
    @ObservationIgnored private var persistTask: Task<Void, Never>?
    @ObservationIgnored private var transferExpirationTasks: [TransferRecord.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var autoReplyTasks: [ChatConversation.ID: Task<Void, Never>] = [:]
    @ObservationIgnored private var readReceiptTasks: [ChatMessage.ID: Task<Void, Never>] = [:]

    init(
        snapshot: MessagesSnapshot? = nil,
        repository: MessagesRepository? = nil,
        callingService: (any CallingService)? = nil,
        transferService: (any TransferService)? = nil,
        groupAdminService: (any GroupAdminService)? = nil,
        messageRequestService: (any MessageRequestService)? = nil
    ) {
        let resolvedRepository = repository ?? LocalMessagesRepository()
        self.repository = resolvedRepository
        self.callingService = callingService ?? LocalCallingService()
        self.transferService = transferService ?? LocalTransferService()
        self.groupAdminService = groupAdminService ?? LocalGroupAdminService()
        self.messageRequestService = messageRequestService ?? LocalMessageRequestService()
        persistenceGeneration = resolvedRepository.currentPersistenceGeneration()
        let resolved = snapshot ?? resolvedRepository.load()
        conversations = resolved.conversations
        friendRequests = resolved.friendRequests
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
    private static func inboxSortRank(_ conversation: ChatConversation) -> Int {
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

        let message = ChatMessage(
            id: UUID(),
            sender: "我",
            text: trimmed,
            sentAt: .now,
            isMe: true,
            replyToSender: replyingTo.map { $0.isMe ? "我" : $0.sender },
            replyToText: replyingTo?.text,
            deliveryStatus: .delivered
        )
        appendMessage(message, to: id)
        scheduleReadReceipt(for: message.id, in: id)
        scheduleDemoAutoReply(to: id)
        return message
    }

    @discardableResult
    func sendPayload(_ message: ChatMessage, to id: ChatConversation.ID) -> ChatMessage? {
        guard index(of: id) != nil else { return nil }
        var outbound = message
        if outbound.deliveryStatus == .sent {
            outbound.deliveryStatus = .delivered
        }
        appendMessage(outbound, to: id)
        if outbound.isMe {
            scheduleReadReceipt(for: outbound.id, in: id)
            scheduleDemoAutoReply(to: id)
        }
        return outbound
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

    private func appendMessage(_ message: ChatMessage, to id: ChatConversation.ID) {
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

    /// 本地演示：好友私聊发出后模拟对方回复
    private func scheduleDemoAutoReply(to id: ChatConversation.ID) {
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

    private func scheduleReadReceipt(for messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
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

    /// 发起好友聊天。已存在时：`deliverGreeting == true` 会把问候作为新消息发出。
    @discardableResult
    func startChat(
        with nickname: String,
        greeting: String = MessagesCopy.defaultGreeting,
        deliverGreeting: Bool = true
    ) -> ChatConversation? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedGreeting = greeting.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if deliverGreeting, !trimmedGreeting.isEmpty {
                let last = threads[existing.id]?.last
                let duplicate = last?.isMe == true && last?.text == trimmedGreeting
                if !duplicate {
                    send(text: trimmedGreeting, to: existing.id)
                }
            }
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let seed = trimmedGreeting.isEmpty ? MessagesCopy.defaultGreeting : trimmedGreeting
        let conversation = ChatConversation(
            id: id,
            title: name,
            subtitle: MessagesCopy.friendSubtitle,
            lastMessage: seed,
            updatedAt: .now,
            unreadCount: 0,
            kind: .direct,
            lastMessageIsMe: true
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [
            ChatMessage(id: UUID(), sender: "我", text: seed, sentAt: .now, isMe: true)
        ]
        persist()
        onConversationsChanged?()
        return conversation
    }

    /// 选好友发起：1 人私聊，2 人及以上建群（含自己为多人）。
    @discardableResult
    func startChat(withMembers nicknames: [String], ownerName: String) -> ChatConversation? {
        let owner = ownerName.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let members: [String] = nicknames.compactMap { raw in
            let name = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !name.isEmpty else { return nil }
            if !owner.isEmpty, name.caseInsensitiveCompare(owner) == .orderedSame { return nil }
            let key = name.lowercased()
            guard !seen.contains(key) else { return nil }
            seen.insert(key)
            return name
        }
        guard !members.isEmpty else { return nil }

        if members.count == 1 {
            return startChat(with: members[0], deliverGreeting: false)
        }

        let memberKey = Set(members.map { $0.lowercased() })
        if let existing = conversations.first(where: { conversation in
            guard conversation.kind == .group else { return false }
            let peers = conversation.memberNames.filter {
                owner.isEmpty || $0.caseInsensitiveCompare(owner) != .orderedSame
            }
            return Set(peers.map { $0.lowercased() }) == memberKey
        }) {
            return existing
        }

        let id = UUID()
        let tip = MessagesCopy.groupCreated
        var allMembers = members
        if !owner.isEmpty {
            allMembers.insert(owner, at: 0)
        }
        let conversation = ChatConversation(
            id: id,
            title: MessagesCopy.peerGroupTitle(members),
            subtitle: MessagesCopy.groupSubtitle,
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .group,
            lastMessageIsMe: false,
            ownerName: owner.isEmpty ? nil : owner,
            memberNames: allMembers
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [ChatMessage.systemTip(tip, audience: .everyone)]
        storeBootstrapMembers(for: conversation)
        persist()
        onConversationsChanged?()
        return conversation
    }

    /// 活动群：一场局一个群；发起人为群主。进群用系统小字，不发问候气泡。
    @discardableResult
    func startGroupChat(
        for activity: Activity,
        role: GroupChatJoinRole = .participant,
        memberName: String = "",
        announceMembership: Bool = false
    ) -> ChatConversation? {
        let displayName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = conversations.first(where: {
            $0.kind == .activity && (
                $0.relatedActivityID == activity.id
                    || ($0.relatedActivityID == nil && $0.title == activity.title)
            )
        }) {
            syncGroupMetadata(conversationID: existing.id, activity: activity)
            if announceMembership, role == .participant, !displayName.isEmpty {
                addMember(displayName, to: existing.id)
            }
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let tip: String
        switch role {
        case .host:
            tip = MessagesCopy.groupCreated
        case .participant:
            tip = displayName.isEmpty
                ? MessagesCopy.memberJoined(MessagesCopy.memberFallback)
                : MessagesCopy.memberJoined(displayName)
        }
        let conversation = ChatConversation(
            id: id,
            title: activity.title,
            subtitle: MessagesCopy.groupSubtitle,
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .activity,
            eventAt: activity.date,
            relatedActivityID: activity.id,
            lastMessageIsMe: false,
            ownerName: activity.hostName,
            memberNames: {
                var names = [activity.hostName]
                if role == .participant, !displayName.isEmpty,
                   displayName.caseInsensitiveCompare(activity.hostName) != .orderedSame {
                    names.append(displayName)
                }
                return names
            }()
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [ChatMessage.systemTip(tip, audience: .everyone)]
        storeBootstrapMembers(for: conversation)
        persist()
        onConversationsChanged?()
        return conversation
    }

    /// 兴趣组织群：加入组织后进入；一组织一群。
    @discardableResult
    func startCircleChat(
        for circle: InterestCircle,
        memberName: String = ""
    ) -> ChatConversation? {
        let displayName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing = conversations.first(where: {
            $0.kind == .circle && (
                $0.relatedCircleID == circle.id
                    || ($0.relatedCircleID == nil && $0.title == circle.name)
            )
        }) {
            if !displayName.isEmpty {
                addMember(displayName, to: existing.id)
            }
            // Sync announcement / mute prefs lightly
            if let index = conversations.firstIndex(where: { $0.id == existing.id }) {
                conversations[index].announcement = circle.summary
                conversations[index].subtitle = MessagesCopy.circleGroupSubtitle
            }
            persist()
            return conversations.first { $0.id == existing.id }
        }

        let id = UUID()
        let tip = displayName.isEmpty
            ? MessagesCopy.groupCreated
            : MessagesCopy.memberJoined(displayName)
        var members = SampleData.circleBuddies
            .filter { $0.circleName == circle.name }
            .map(\.profile.nickname)
        if !displayName.isEmpty,
           !members.contains(where: { $0.caseInsensitiveCompare(displayName) == .orderedSame }) {
            members.insert(displayName, at: 0)
        }
        let conversation = ChatConversation(
            id: id,
            title: circle.name,
            subtitle: MessagesCopy.circleGroupSubtitle,
            lastMessage: tip,
            updatedAt: .now,
            unreadCount: 0,
            kind: .circle,
            relatedCircleID: circle.id,
            lastMessageIsMe: false,
            ownerName: members.first,
            memberNames: members,
            announcement: circle.summary
        )
        conversations.insert(conversation, at: 0)
        threads[id] = [ChatMessage.systemTip(tip, audience: .everyone)]
        storeBootstrapMembers(for: conversation)
        persist()
        return conversation
    }

    /// 退出组织群：从列表移除本机会话（演示）
    func leaveCircleChat(circleID: InterestCircle.ID, leaverName: String) {
        guard let conversation = conversations.first(where: {
            $0.kind == .circle && $0.relatedCircleID == circleID
        }) else { return }
        let name = leaverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipName = name.isEmpty ? MessagesCopy.memberFallback : name
        appendSystemTip(
            MessagesCopy.memberLeft(tipName),
            audience: .everyone,
            to: conversation.id
        )
        delete(conversation.id)
        onConversationsChanged?()
    }

    func conversation(forCircleID id: InterestCircle.ID) -> ChatConversation? {
        conversations.first { $0.kind == .circle && $0.relatedCircleID == id }
    }

    /// 退出活动群：写入仅群主可见的退群小字；非群主从自己的列表移除会话。
    func leaveGroupChat(
        activityID: Activity.ID,
        leaverName: String,
        currentUserIsOwner: Bool
    ) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activityID
        }) else { return }

        let name = leaverName.trimmingCharacters(in: .whitespacesAndNewlines)
        let tipName = name.isEmpty ? MessagesCopy.memberFallback : name
        appendSystemTip(
            MessagesCopy.memberLeft(tipName),
            audience: .hostOnly,
            to: conversation.id
        )

        if currentUserIsOwner {
            persist()
            return
        }
        delete(conversation.id)
        onConversationsChanged?()
    }

    /// 活动改期 / 改标题后同步群聊元数据
    func syncGroupMetadata(for activity: Activity) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activity.id
        }) else { return }
        syncGroupMetadata(conversationID: conversation.id, activity: activity)
    }

    /// 主办取消活动：群聊系统通知 + 更新副标题
    func announceActivityCancelled(activity: Activity) {
        guard let conversation = conversations.first(where: {
            $0.kind == .activity && $0.relatedActivityID == activity.id
        }) else { return }
        guard let index = index(of: conversation.id) else { return }

        let notice = "【活动取消】发起人已取消「\(activity.title)」。"
        appendSystemTip(notice, audience: .everyone, to: conversation.id)
        conversations[index].subtitle = ActivityDetailCopy.hostCancelledNotice
        conversations[index].updatedAt = .now
        persist()
        onConversationsChanged?()
    }

    /// 对指定观众可见的消息（退群小字仅群主可见）
    func visibleMessages(
        for id: ChatConversation.ID,
        viewerName: String,
        ownerName: String?
    ) -> [ChatMessage] {
        let isOwner = ownerName.map {
            $0.caseInsensitiveCompare(viewerName) == .orderedSame
        } ?? false
        return (threads[id] ?? []).filter { message in
            guard message.isSystem, message.systemAudience == .hostOnly else { return true }
            return isOwner
        }
    }

    func groupMembers(for id: ChatConversation.ID) -> [GroupMemberRecord] {
        groupMembersByConversation[id]
            ?? groupAdminService.bootstrapMembers(
                ownerName: conversations.first(where: { $0.id == id })?.ownerName,
                memberNames: conversations.first(where: { $0.id == id })?.memberNames ?? []
            )
    }

    func role(of nickname: String, in conversationID: ChatConversation.ID) -> GroupMemberRole {
        groupMembers(for: conversationID).first {
            $0.nickname.caseInsensitiveCompare(nickname) == .orderedSame
        }?.role ?? .member
    }

    func activeCall(for conversationID: ChatConversation.ID) -> CallSessionRecord? {
        callRecords
            .filter { $0.conversationID == conversationID && $0.status.isLive }
            .sorted { $0.startedAt > $1.startedAt }
            .first
    }

    func recentCalls(for conversationID: ChatConversation.ID) -> [CallSessionRecord] {
        callRecords
            .filter { $0.conversationID == conversationID }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func transfers(for conversationID: ChatConversation.ID) -> [TransferRecord] {
        self.transferRecords
            .filter { $0.conversationID == conversationID }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func transferRecord(for message: ChatMessage) -> TransferRecord? {
        if let transferID = message.transferID {
            return transferRecords.first { $0.id == transferID }
        }
        guard let amount = message.transferAmount else { return nil }
        return transferRecords.first {
            $0.messageID == message.id || ($0.amount == amount && $0.createdAt == message.sentAt)
        }
    }

    func requestSourceLabel(for conversation: ChatConversation) -> String {
        messageRequestService.requestSource(for: conversation).rawValue
    }

    func requestPreview(for conversation: ChatConversation) -> String {
        messageRequestService.requestPreview(for: conversation)
    }

    private func appendSystemTip(
        _ text: String,
        audience: ChatSystemAudience,
        to id: ChatConversation.ID
    ) {
        guard let index = index(of: id) else { return }
        if let last = threads[id]?.last,
           last.isSystem,
           last.text == text,
           last.systemAudience == audience {
            return
        }
        let tip = ChatMessage.systemTip(text, audience: audience)
        threads[id, default: []].append(tip)
        conversations[index].lastMessage = text
        conversations[index].lastMessageIsMe = false
        conversations[index].updatedAt = tip.sentAt
        persist()
        onConversationsChanged?()
    }

    private func syncGroupMetadata(conversationID: ChatConversation.ID, activity: Activity) {
        guard let index = index(of: conversationID) else { return }
        var changed = false
        if conversations[index].title != activity.title {
            conversations[index].title = activity.title
            changed = true
        }
        if conversations[index].eventAt != activity.date {
            conversations[index].eventAt = activity.date
            changed = true
        }
        if conversations[index].relatedActivityID != activity.id {
            conversations[index].relatedActivityID = activity.id
            changed = true
        }
        if conversations[index].ownerName != activity.hostName {
            conversations[index].ownerName = activity.hostName
            changed = true
        }
        if changed { persist() }
    }

    /// 把社区分享发到好友会话
    @discardableResult
    func shareCommunityPost(
        title: String,
        preview: String,
        to nickname: String,
        postID: UUID? = nil
    ) -> ChatConversation? {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return nil }

        let text = "【社区分享】\(title)\n\(preview)"
        let card = ChatMessage(
            id: UUID(),
            sender: "我",
            text: title,
            sentAt: .now,
            isMe: true,
            messageKind: .link,
            linkTitle: title,
            linkSubtitle: preview,
            linkURLString: postID.map { "zuobiaoxi://community/\($0.uuidString)" },
            deliveryStatus: .delivered
        )
        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            _ = sendPayload(card, to: existing.id)
            return existing
        }
        guard let created = startChat(with: name, greeting: text, deliverGreeting: false) else { return nil }
        _ = sendPayload(card, to: created.id)
        return created
    }

    // MARK: - Calling / transfer / group admin / requests

    @discardableResult
    func startVoiceCall(in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        startCall(kind: .voice, in: conversationID)
    }

    @discardableResult
    func startVideoCall(in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        startCall(kind: .video, in: conversationID)
    }

    @discardableResult
    private func startCall(kind: CallSessionKind, in conversationID: ChatConversation.ID) -> CallSessionRecord? {
        guard index(of: conversationID) != nil else { return nil }
        if let active = activeCall(for: conversationID) { return active }
        let call = callingService.startCall(kind: kind, conversationID: conversationID)
        callRecords.insert(call, at: 0)
        appendSystemTip("已发起\(kind.rawValue)", audience: .everyone, to: conversationID)
        persist()
        return call
    }

    func connectCall(_ callID: CallSessionRecord.ID) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }),
              callRecords[index].status == .ringing || callRecords[index].status == .connecting
        else { return }
        callRecords[index].status = .active
        callRecords[index].connectedAt = .now
        persist()
    }

    func endCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .ended)
    }

    func rejectCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .rejected)
    }

    func cancelCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .cancelled)
    }

    func missCall(_ callID: CallSessionRecord.ID) {
        updateCall(callID, to: .missed)
    }

    private func updateCall(_ callID: CallSessionRecord.ID, to status: CallSessionStatus) {
        guard let index = callRecords.firstIndex(where: { $0.id == callID }) else { return }
        guard callRecords[index].status != status else { return }
        callRecords[index].status = status
        if callRecords[index].connectedAt == nil, status == .active {
            callRecords[index].connectedAt = .now
        }
        if status == .ended || status == .missed || status == .cancelled || status == .rejected {
            callRecords[index].endedAt = .now
            appendSystemTip(callSummary(callRecords[index]), audience: .everyone, to: callRecords[index].conversationID)
        }
        persist()
    }

    private func callSummary(_ record: CallSessionRecord) -> String {
        switch record.status {
        case .missed:
            return "\(record.kind.rawValue)未接听"
        case .cancelled:
            return "\(record.kind.rawValue)已取消"
        case .rejected:
            return "\(record.kind.rawValue)已拒绝"
        case .ended:
            if let connectedAt = record.connectedAt, let endedAt = record.endedAt {
                let duration = max(Int(endedAt.timeIntervalSince(connectedAt)), 0)
                let minute = duration / 60
                let second = duration % 60
                return "\(record.kind.rawValue) \(String(format: "%02d:%02d", minute, second))"
            }
            return "\(record.kind.rawValue)已结束"
        case .ringing, .connecting, .active:
            return record.kind.rawValue
        }
    }

    @discardableResult
    func sendTransfer(
        amount: Double,
        to id: ChatConversation.ID,
        currentUserName: String
    ) -> ChatMessage? {
        guard let conversation = conversations.first(where: { $0.id == id }) else { return nil }
        let recipient = conversation.kind == .direct ? conversation.title : conversation.ownerName ?? MessagesCopy.memberFallback
        let result = transferService.createTransfer(
            conversationID: id,
            amount: amount,
            senderName: currentUserName,
            recipientName: recipient
        )
        transferRecords.insert(result.record, at: 0)
        appendMessage(result.message, to: id)
        scheduleTransferExpiration(for: result.record.id)
        return result.message
    }

    /// 启动 / 重载 / 会话出现时：推进已到期转账，并为待收款重挂定时器
    func refreshTransferExpirations() {
        for task in transferExpirationTasks.values {
            task.cancel()
        }
        transferExpirationTasks.removeAll()

        for record in transferRecords where record.status == .pending {
            if record.isPastExpiration {
                expireTransfer(record.id)
            } else {
                scheduleTransferExpiration(for: record.id)
            }
        }
    }

    func acceptTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .accepted)
    }

    func cancelTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .cancelled)
    }

    func refundTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .refunded)
    }

    func expireTransfer(_ transferID: TransferRecord.ID) {
        updateTransfer(transferID, to: .expired)
    }

    private func updateTransfer(_ transferID: TransferRecord.ID, to status: TransferStatus) {
        guard let index = transferRecords.firstIndex(where: { $0.id == transferID }) else { return }
        let previousStatus = transferRecords[index].status
        guard previousStatus != status else { return }
        if previousStatus == .pending {
            cancelTransferExpiration(for: transferID)
        }
        transferRecords[index] = transferService.advanceStatus(for: transferRecords[index], to: status)
        if status == .expired {
            let record = transferRecords[index]
            appendSystemTip(
                MessagesCopy.transferExpiredNotice(amount: record.amount),
                audience: .everyone,
                to: record.conversationID
            )
        } else {
            persist()
        }
    }

    private func scheduleTransferExpiration(for transferID: TransferRecord.ID) {
        transferExpirationTasks[transferID]?.cancel()
        guard let index = transferRecords.firstIndex(where: { $0.id == transferID }),
              transferRecords[index].status == .pending
        else { return }

        let delay = transferRecords[index].expiresAt.timeIntervalSinceNow
        if delay <= 0 {
            expireTransfer(transferID)
            return
        }

        transferExpirationTasks[transferID] = Task { @MainActor in
            defer { transferExpirationTasks[transferID] = nil }
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled,
                  let idx = transferRecords.firstIndex(where: { $0.id == transferID }),
                  transferRecords[idx].status == .pending
            else { return }
            expireTransfer(transferID)
        }
    }

    private func cancelTransferExpiration(for transferID: TransferRecord.ID) {
        transferExpirationTasks[transferID]?.cancel()
        transferExpirationTasks[transferID] = nil
    }

    func inviteMembers(_ nicknames: [String], to conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.inviteMembers(existing: current, nicknames: nicknames)
        applyGroupMemberMutation(result, to: conversationID)
    }

    func removeMember(_ nickname: String, from conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.removeMember(existing: current, nickname: nickname)
        applyGroupMemberMutation(result, to: conversationID)
    }

    func updateMemberRole(_ nickname: String, role: GroupMemberRole, in conversationID: ChatConversation.ID) {
        let current = groupMembers(for: conversationID)
        let result = groupAdminService.updateRole(existing: current, nickname: nickname, role: role)
        applyGroupMemberMutation(result, to: conversationID)
    }

    private func applyGroupMemberMutation(
        _ result: GroupMemberMutationResult,
        to conversationID: ChatConversation.ID
    ) {
        groupMembersByConversation[conversationID] = result.members
        if let index = index(of: conversationID) {
            conversations[index].memberNames = result.members.map(\.nickname)
        }
        if let systemMessage = result.systemMessage, !systemMessage.isEmpty {
            appendSystemTip(systemMessage, audience: .everyone, to: conversationID)
        } else {
            persist()
        }
    }

    // MARK: - Rich payloads / group / social

    func sendImage(localName: String, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: MessagesCopy.imagePlaceholder, sentAt: .now, isMe: true,
                messageKind: .image, mediaLocalName: localName
            ),
            to: id
        )
    }

    func sendVoice(duration: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: "[语音]", sentAt: .now, isMe: true,
                messageKind: .voice, voiceDuration: duration
            ),
            to: id
        )
    }

    func sendLocation(name: String, latitude: Double, longitude: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: name, sentAt: .now, isMe: true,
                messageKind: .location, locationName: name, latitude: latitude, longitude: longitude
            ),
            to: id
        )
    }

    func sendActivityCard(_ activity: Activity, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: activity.title, sentAt: .now, isMe: true,
                messageKind: .activity,
                linkSubtitle: "\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)",
                cardActivityID: activity.id
            ),
            to: id
        )
    }

    func sendTransfer(amount: Double, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: MessagesCopy.transferTitle, sentAt: .now, isMe: true,
                messageKind: .transfer, transferAmount: amount
            ),
            to: id
        )
    }

    func sendSticker(_ emoji: String, to id: ChatConversation.ID) -> ChatMessage? {
        sendPayload(
            ChatMessage(
                id: UUID(), sender: "我", text: emoji, sentAt: .now, isMe: true,
                messageKind: .sticker
            ),
            to: id
        )
    }

    func setReaction(_ emoji: String?, on messageID: ChatMessage.ID, in conversationID: ChatConversation.ID) {
        guard var list = threads[conversationID],
              let idx = list.firstIndex(where: { $0.id == messageID })
        else { return }
        list[idx].reaction = emoji
        if emoji == "❤️" { list[idx].isLiked = true }
        threads[conversationID] = list
        persist()
    }

    func updateAnnouncement(_ text: String, for conversationID: ChatConversation.ID) {
        guard let index = index(of: conversationID) else { return }
        conversations[index].announcement = text.trimmingCharacters(in: .whitespacesAndNewlines)
        appendSystemTip(MessagesCopy.announcementUpdated, audience: .everyone, to: conversationID)
    }

    func renameGroup(_ title: String, for conversationID: ChatConversation.ID) {
        guard let index = index(of: conversationID) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        conversations[index].title = trimmed
        appendSystemTip(MessagesCopy.groupRenamed(trimmed), audience: .everyone, to: conversationID)
    }

    func kickMember(_ name: String, from conversationID: ChatConversation.ID) {
        removeMember(name, from: conversationID)
    }

    func addMember(_ name: String, to conversationID: ChatConversation.ID) {
        inviteMembers([name], to: conversationID)
    }

    func acceptMessageRequest(_ id: ChatConversation.ID) {
        guard let index = index(of: id) else { return }
        conversations[index].isMessageRequest = false
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

        // 去掉同名消息请求，避免双入口
        for request in messageRequests where request.title.caseInsensitiveCompare(name) == .orderedSame {
            delete(request.id)
        }

        if let existing = conversations.first(where: {
            $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame
        }) {
            if let cidx = index(of: existing.id) {
                conversations[cidx].isMessageRequest = false
                conversations[cidx].peerIsActive = true
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
                peerIsActive: true
            )
            conversations.insert(conversation, at: 0)
            threads[chatID] = [
                ChatMessage(id: UUID(), sender: name, text: message, sentAt: .now, isMe: false)
            ]
        }
        persist()
    }

    func declineFriendRequest(_ id: FriendRequest.ID) {
        guard let idx = friendRequests.firstIndex(where: { $0.id == id }) else { return }
        friendRequests[idx].status = .declined
        persist()
    }

    /// 按昵称删除好友会话（拉黑时调用）
    func deleteDirectChat(with nickname: String) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let ids = conversations
            .filter { $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame }
            .map(\.id)
        ids.forEach { id in
            conversations.removeAll { $0.id == id }
            threads[id] = nil
            groupMembersByConversation[id] = nil
        }
        transferRecords.removeAll { ids.contains($0.conversationID) }
        callRecords.removeAll { ids.contains($0.conversationID) }
        clearFriendProfile(for: name, persistAfter: false)
        persist()
    }

    func remark(for nickname: String) -> String {
        friendRemarks[Self.friendKey(nickname)] ?? ""
    }

    func group(for nickname: String) -> String {
        let value = friendGroups[Self.friendKey(nickname)] ?? ""
        return value.isEmpty ? MessagesCopy.friendGroupUngrouped : value
    }

    func displayName(for nickname: String) -> String {
        let remark = remark(for: nickname).trimmingCharacters(in: .whitespacesAndNewlines)
        return remark.isEmpty ? nickname : remark
    }

    func setRemark(_ remark: String, for nickname: String) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        let trimmed = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            friendRemarks.removeValue(forKey: key)
        } else {
            friendRemarks[key] = trimmed
        }
        persist()
    }

    func setGroup(_ group: String, for nickname: String) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        let trimmed = group.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == MessagesCopy.friendGroupUngrouped {
            friendGroups.removeValue(forKey: key)
        } else {
            friendGroups[key] = trimmed
        }
        persist()
    }

    /// 删除好友：清会话与备注/分组
    func deleteFriend(named nickname: String) {
        deleteDirectChat(with: nickname)
    }

    private func clearFriendProfile(for nickname: String, persistAfter: Bool = true) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        friendRemarks.removeValue(forKey: key)
        friendGroups.removeValue(forKey: key)
        if persistAfter { persist() }
    }

    private static func friendKey(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    func searchHistory(query: String) -> [ChatHistoryHit] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        var hits: [ChatHistoryHit] = []
        for conversation in conversations where !conversation.isMessageRequest {
            for message in threads[conversation.id] ?? [] where !message.isSystem {
                let hay = [
                    message.text,
                    message.linkTitle,
                    message.linkSubtitle,
                    message.locationName,
                    message.previewText
                ].compactMap { $0 }.joined(separator: " ")
                if hay.localizedCaseInsensitiveContains(trimmed) {
                    hits.append(
                        ChatHistoryHit(
                            id: UUID(),
                            conversationID: conversation.id,
                            conversationTitle: conversation.title,
                            messageID: message.id,
                            snippet: message.previewText,
                            sentAt: message.sentAt
                        )
                    )
                }
            }
        }
        return hits.sorted { $0.sentAt > $1.sentAt }
    }

    private func index(of id: ChatConversation.ID) -> Int? {
        conversations.firstIndex { $0.id == id }
    }

    private func bootstrapGroupMembersIfNeeded() {
        for conversation in conversations where conversation.isGroup {
            if groupMembersByConversation[conversation.id]?.isEmpty != false {
                groupMembersByConversation[conversation.id] = groupAdminService.bootstrapMembers(
                    ownerName: conversation.ownerName,
                    memberNames: conversation.memberNames
                )
            }
        }
    }

    private func storeBootstrapMembers(for conversation: ChatConversation) {
        guard conversation.isGroup else { return }
        groupMembersByConversation[conversation.id] = groupAdminService.bootstrapMembers(
            ownerName: conversation.ownerName,
            memberNames: conversation.memberNames
        )
    }

    private func normalizeMessageRequests() {
        for index in conversations.indices where conversations[index].isMessageRequest {
            if conversations[index].requestSource == nil {
                conversations[index].requestSource = .directMessage
            }
            if conversations[index].requestPreviewText?.isEmpty != false {
                conversations[index].requestPreviewText = conversations[index].inboxPreview
            }
        }
    }

    /// 用线程最后一条对齐收件箱预览；并把旧「私聊/活动群」副标题归一为好友/群聊
    private func reconcileInboxPreviews() {
        var changed = false
        for index in conversations.indices {
            let id = conversations[index].id
            if let last = threads[id]?.last {
                let preview = last.previewText
                if conversations[index].lastMessage != preview {
                    conversations[index].lastMessage = preview
                    changed = true
                }
                if conversations[index].lastMessageIsMe != last.isMe {
                    conversations[index].lastMessageIsMe = last.isMe
                    changed = true
                }
                if conversations[index].updatedAt != last.sentAt {
                    conversations[index].updatedAt = last.sentAt
                    changed = true
                }
            }

            switch conversations[index].kind {
            case .direct:
                if conversations[index].subtitle != MessagesCopy.friendSubtitle {
                    conversations[index].subtitle = MessagesCopy.friendSubtitle
                    changed = true
                }
            case .activity, .group:
                if conversations[index].subtitle != MessagesCopy.groupSubtitle {
                    conversations[index].subtitle = MessagesCopy.groupSubtitle
                    changed = true
                }
                if conversations[index].kind == .activity, conversations[index].memberNames.isEmpty {
                    var members = conversations[index].ownerName.map { [$0] } ?? []
                    if !members.contains(where: { $0 == "林屿" || $0 == "我" }) {
                        members.append("林屿")
                    }
                    conversations[index].memberNames = members
                    changed = true
                }
            case .circle:
                if conversations[index].subtitle != MessagesCopy.circleGroupSubtitle {
                    conversations[index].subtitle = MessagesCopy.circleGroupSubtitle
                    changed = true
                }
            case .notice:
                if conversations[index].subtitle != MessagesCopy.noticeSubtitle {
                    conversations[index].subtitle = MessagesCopy.noticeSubtitle
                    changed = true
                }
            }
        }
        if changed { persist() }
    }

    func reloadFromRepository() async {
        guard let snapshot = try? await repository.loadAsync() else { return }
        persistenceGeneration = repository.currentPersistenceGeneration()
        conversations = snapshot.conversations
        friendRequests = snapshot.friendRequests
        friendRemarks = snapshot.friendRemarks
        friendGroups = snapshot.friendGroups
        groupMembersByConversation = Dictionary(
            uniqueKeysWithValues: snapshot.groupMembers.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        transferRecords = snapshot.transferRecords
        callRecords = snapshot.callRecords
        threads = Dictionary(
            uniqueKeysWithValues: snapshot.threads.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
        bootstrapGroupMembersIfNeeded()
        normalizeMessageRequests()
        reconcileInboxPreviews()
        refreshTransferExpirations()
    }

    func discardPendingPersistence() async {
        for task in autoReplyTasks.values {
            task.cancel()
        }
        autoReplyTasks.removeAll()
        for task in readReceiptTasks.values {
            task.cancel()
        }
        readReceiptTasks.removeAll()
        for task in transferExpirationTasks.values {
            task.cancel()
        }
        transferExpirationTasks.removeAll()
        persistTask?.cancel()
        _ = await persistTask?.result
        persistTask = nil
        repository.invalidatePendingWrites()
        persistenceGeneration = repository.currentPersistenceGeneration()
    }

    private func persist() {
        let snapshot = MessagesSnapshot(
            conversations: conversations,
            threads: Dictionary(
                uniqueKeysWithValues: threads.map { ($0.key.uuidString, $0.value) }
            ),
            friendRequests: friendRequests,
            friendRemarks: friendRemarks,
            friendGroups: friendGroups,
            groupMembers: Dictionary(
                uniqueKeysWithValues: groupMembersByConversation.map { ($0.key.uuidString, $0.value) }
            ),
            transferRecords: transferRecords,
            callRecords: callRecords
        )
        let previousTask = persistTask
        let generation = persistenceGeneration
        persistTask = Task {
            _ = await previousTask?.result
            guard !Task.isCancelled else { return }
            try? await repository.replaceAsync(with: snapshot, generation: generation)
        }
    }
}

enum GroupChatJoinRole: Equatable {
    /// 发布活动创建群
    case host
    /// 报名加入群
    case participant
}

