// Module: SparkMessages — Network-first repository with cache fallback.

import Foundation
import SparkCore
import SparkNetworking

public struct LiveMessagesRepository: MessagesRepository, Sendable {
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
            if let cached = await cache.get() {
                return cached
            }
            throw MessagesError.underlying(mapToAppError(error))
        }
    }

    public func fetchThreads() async throws -> [MessageThread] {
        do {
            let dto: MessageThreadsResponseDTO = try await apiClient.get(MessagesAPIPath.threads)
            return try dto.threads.map(MessagesDTOMapper.thread)
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
