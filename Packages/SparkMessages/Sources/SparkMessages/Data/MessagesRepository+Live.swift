// Module: SparkMessages — Network-first repository with cache fallback.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveMessagesRepository: MessagesRepository, Sendable {
    private static let logger = SparkLog.logger(category: "Messages.Live")

    private let apiClient: APIClient
    private let cache: MessagesCache

    public init(apiClient: APIClient, cache: MessagesCache) {
        self.apiClient = apiClient
        self.cache = cache
    }

    public func fetchUnreadCount() async throws -> Int {
        do {
            let dto: MessagesUnreadDTO = try await apiClient.get(MessagesAPIPath.unreadCount)
            await cache.set(dto.count)
            return dto.count
        } catch {
            Self.logger.error("fetchUnreadCount failed: \(error.localizedDescription, privacy: .public)")
            if let cached = await cache.get() {
                return cached
            }
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func fetchThreads() async throws -> [MessageThread] {
        try await fetchInbox().allThreads.sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    public func fetchInbox() async throws -> MessagesInbox {
        do {
            let dto: MessagesInboxResponseDTO = try await apiClient.get(MessagesAPIPath.inbox)
            return try MessagesDTOMapper.inbox(from: dto)
        } catch let error as MessagesError {
            if case let .underlying(.server(code, _)) = error, code == 404 {
                return try await derivedInbox()
            }
            throw error
        } catch {
            if let appError = error as? AppError, case let .server(code, _) = appError, code == 404 {
                return try await derivedInbox()
            }
            Self.logger.error("fetchInbox failed: \(error.localizedDescription, privacy: .public)")
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func dismissInboxActionItem(id: String) async throws {
        do {
            try await apiClient.post(MessagesAPIPath.dismissActionItem(id: id))
        } catch {
            Self.logger.error(
                "dismissInboxActionItem failed for \(id, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext {
        do {
            let dto: ConversationContextResponseDTO = try await apiClient.get(
                MessagesAPIPath.conversationContext(threadID: threadID.rawValue)
            )
            return try MessagesDTOMapper.conversationContext(from: dto)
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws {
        let body = try JSONEncoder().encode(
            InvitationRespondRequestDTO(response: accept ? "accept" : "decline")
        )
        do {
            try await apiClient.post(
                MessagesAPIPath.invitationRespond(activityID: activityID, invitationID: invitationID),
                body: body
            )
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] {
        do {
            let path = MessagesAPIPath.threadMessages(threadID: threadID.rawValue)
            let dto: ThreadMessagesResponseDTO = try await apiClient.get(path)
            return try dto.messages.map(MessagesDTOMapper.message)
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage {
        let requestBody = try JSONEncoder().encode(SendMessageRequestDTO(body: body))
        let path = MessagesAPIPath.threadMessages(threadID: threadID.rawValue)
        do {
            let dto: ChatMessageDTO = try await apiClient.post(path, body: requestBody)
            return try MessagesDTOMapper.message(from: dto)
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func markAllRead() async throws {
        do {
            try await apiClient.post(MessagesAPIPath.markRead)
            await cache.clear()
        } catch {
            await cache.clear()
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func markThreadRead(threadID: MessageThreadID) async throws {
        do {
            try await apiClient.post(MessagesAPIPath.markThreadRead(threadID: threadID.rawValue))
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID {
        let body = try JSONEncoder().encode(
            EnsureDirectMessageThreadRequestDTO(peerUserID: peerUserID, peerDisplayName: peerDisplayName)
        )
        do {
            let dto: DirectMessageThreadResponseDTO = try await apiClient.post(
                MessagesAPIPath.directThreads,
                body: body
            )
            return MessageThreadID(dto.threadID)
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        let body = try JSONEncoder().encode(
            EnsureActivityGroupThreadRequestDTO(
                threadId: threadID.rawValue,
                displayName: displayName,
                welcomeMessage: welcomeMessage
            )
        )
        do {
            try await apiClient.post(MessagesAPIPath.activityGroupThreads, body: body)
        } catch {
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    private func derivedInbox() async throws -> MessagesInbox {
        let dto: MessageThreadsResponseDTO = try await apiClient.get(MessagesAPIPath.threads)
        let threads = try dto.threads.map(MessagesDTOMapper.thread)
        let dm = threads.filter(\.threadID.isDirectMessage).map { thread in
            ConversationPreview(
                threadID: thread.threadID,
                kind: .dm,
                displayName: thread.peerDisplayName,
                lastMessagePreview: thread.lastMessagePreview,
                lastMessageAt: thread.lastActivityAt,
                unreadCount: thread.unreadCount
            )
        }
        let groups = threads.filter(\.threadID.isGroupChat).map { thread in
            ConversationPreview(
                threadID: thread.threadID,
                kind: .groupChat,
                displayName: thread.peerDisplayName,
                lastMessagePreview: thread.lastMessagePreview,
                lastMessageAt: thread.lastActivityAt,
                unreadCount: thread.unreadCount
            )
        }
        return MessagesInbox(dmConversations: dm, activeGroupChats: groups)
    }

    private func mapToAppError(_ error: Error) -> AppError {
        if let messagesError = error as? MessagesError,
           case let .underlying(appError) = messagesError {
            return appError
        }
        if let appError = error as? AppError {
            return appError
        }
        return .unknown(message: error.localizedDescription)
    }
}
