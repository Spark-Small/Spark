//
//  MessagesModel.swift
//  坐标系
//
//  会话商店：对齐 FoundationChat 式「列表 ↔ 详情」共享状态
//

import CoordinateDomain
import CoordinateModels
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
    /// 用户自建好友分组名（保序）
    var friendGroupCatalog: [String]
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
        friendGroupCatalog = resolved.friendGroupCatalog
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

    func existingGroupChat(for activity: Activity) -> ChatConversation? {
        conversations.first {
            $0.kind == .activity && (
                $0.relatedActivityID == activity.id
                    || ($0.relatedActivityID == nil && $0.title == activity.title)
            )
        }
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
}
