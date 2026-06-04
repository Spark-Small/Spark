// Module: SparkMessages — Data access boundary for the messages feature.

import Foundation

public protocol MessagesRepository: Sendable {
    func fetchUnreadCount() async throws -> Int
    func fetchThreads() async throws -> [MessageThread]
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage]
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage
    func markAllRead() async throws
    /// Ensures an activity group thread exists after signup (Mock creates locally; Live joins on server).
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws
    /// Creates or returns a 1:1 thread after mutual like (Likes tab).
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID
}
