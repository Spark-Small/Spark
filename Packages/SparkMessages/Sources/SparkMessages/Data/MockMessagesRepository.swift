// Module: SparkMessages — Preview and test double with inbox + conversation data.

import Foundation

/// In-memory repository for previews, tests, and mock API hosts.
public actor MockMessagesRepository: MessagesRepository {
    private var threads: [MessageThread]
    private var messagesByThread: [String: [ChatMessage]]
    public private(set) var markReadCallCount = 0

    public init(unreadCount: Int = 3) {
        let now = Date()
        // REASONING: Only threads for activities the mock user already joined (act_1) or hosts (act_3).
        let hike = MessageThread(
            threadID: MessageThreadID("th_activity_act_1"),
            peerDisplayName: String(
                localized: "activity.groupChat.hike.name",
                defaultValue: "周末徒步 · 群",
                comment: "Activity group name"
            ),
            lastMessagePreview: String(
                localized: "activity.groupChat.hike.preview",
                defaultValue: "周六 9:30 北门集合",
                comment: "Group preview"
            ),
            lastActivityAt: now.addingTimeInterval(-300),
            unreadCount: unreadCount
        )
        let run = MessageThread(
            threadID: MessageThreadID("th_activity_act_3"),
            peerDisplayName: String(
                localized: "activity.groupChat.run.name",
                defaultValue: "跑步打卡 · 群",
                comment: "Activity group name"
            ),
            lastMessagePreview: String(
                localized: "activity.groupChat.run.preview",
                defaultValue: "明早 7:00 滨江入口见",
                comment: "Group preview"
            ),
            lastActivityAt: now.addingTimeInterval(-3600),
            unreadCount: 0
        )
        threads = [hike, run]
        messagesByThread = [
            hike.threadID.rawValue: Self.seedGroupMessages(for: hike, now: now),
            run.threadID.rawValue: Self.seedGroupMessages(for: run, now: now.addingTimeInterval(-1800)),
        ]
    }

    public func fetchUnreadCount() async throws -> Int {
        threads.reduce(0) { $0 + $1.unreadCount }
    }

    public func fetchThreads() async throws -> [MessageThread] {
        threads.sorted { $0.lastActivityAt > $1.lastActivityAt }
    }

    public func fetchMessages(threadID: MessageThreadID) async throws -> [ChatMessage] {
        messagesByThread[threadID.rawValue] ?? []
    }

    public func sendMessage(threadID: MessageThreadID, body: String) async throws -> ChatMessage {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessagesError.underlying(.unknown(message: "Empty message"))
        }
        let message = ChatMessage(
            id: "msg_mock_\(UUID().uuidString.prefix(8))",
            threadID: threadID,
            body: trimmed,
            sentAt: Date(),
            isFromCurrentUser: true
        )
        var list = messagesByThread[threadID.rawValue] ?? []
        list.append(message)
        messagesByThread[threadID.rawValue] = list
        if let index = threads.firstIndex(where: { $0.threadID == threadID }) {
            let existing = threads[index]
            threads[index] = MessageThread(
                threadID: existing.threadID,
                peerDisplayName: existing.peerDisplayName,
                lastMessagePreview: trimmed,
                lastActivityAt: message.sentAt,
                unreadCount: existing.unreadCount
            )
        }
        return message
    }

    public func markAllRead() async throws {
        markReadCallCount += 1
        threads = threads.map { thread in
            MessageThread(
                threadID: thread.threadID,
                peerDisplayName: thread.peerDisplayName,
                lastMessagePreview: thread.lastMessagePreview,
                lastActivityAt: thread.lastActivityAt,
                unreadCount: 0
            )
        }
    }

    public func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        guard !threads.contains(where: { $0.threadID == threadID }) else { return }
        let now = Date()
        let thread = MessageThread(
            threadID: threadID,
            peerDisplayName: displayName,
            lastMessagePreview: welcomeMessage,
            lastActivityAt: now,
            unreadCount: 0
        )
        threads.insert(thread, at: 0)
        messagesByThread[threadID.rawValue] = [
            ChatMessage(
                id: "msg_welcome_\(threadID.rawValue)",
                threadID: threadID,
                body: welcomeMessage,
                sentAt: now,
                isFromCurrentUser: false
            ),
        ]
    }

    private static func seedGroupMessages(for thread: MessageThread, now: Date) -> [ChatMessage] {
        [
            ChatMessage(
                id: "msg_seed_1_\(thread.threadID.rawValue)",
                threadID: thread.threadID,
                body: thread.lastMessagePreview,
                sentAt: now,
                isFromCurrentUser: false
            ),
        ]
    }
}
