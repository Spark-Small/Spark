// Module: SparkMessages — Data access boundary for the messages feature.

import Foundation

/// Thread list, inbox, and conversation operations for the Messages tab.
public protocol MessagesRepository: Sendable {
    /// Legacy unread badge endpoint; prefer inbox-derived counts in UI.
    func fetchUnreadCount() async throws -> Int

    /// Flat thread list sorted by recent activity.
    func fetchThreads() async throws -> [MessageThread]

    /// Unified inbox payload (action items, matches, DM, group chats).
    func fetchInbox() async throws -> MessagesInbox

    /// Messages in a single thread.
    func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage]

    /// DM shared activities and relationship metadata for conversation header.
    func fetchConversationContext(threadID: MessageThreadID) async throws -> ConversationContext

    /// Send a user-authored text message.
    func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage

    /// Clears unread counts for DM and group conversations (not action items).
    func markAllRead() async throws

    /// Clears unread count for one thread.
    func markThreadRead(threadID: MessageThreadID) async throws

    /// Accept or decline an activity invite from an action card.
    func respondToActivityInvite(activityID: String, invitationID: String, accept: Bool) async throws

    /// Dismiss a change / waitlist action card so it does not reappear after reload.
    func dismissInboxActionItem(id: String) async throws

    /// Ensures an activity group thread exists after signup (Mock creates locally; Live joins on server).
    func ensureActivityGroupThread(threadID: MessageThreadID, displayName: String, welcomeMessage: String) async throws

    /// Creates or returns a 1:1 thread after mutual like (Likes tab).
    func ensureDirectMessageThread(peerUserID: String, peerDisplayName: String) async throws -> MessageThreadID
}
