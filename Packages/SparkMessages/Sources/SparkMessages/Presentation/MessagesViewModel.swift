// Module: SparkMessages — Messages inbox state.

import Foundation
import Observation
import SparkCore

@MainActor
@Observable
public final class MessagesViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case empty
        case failure(String)
    }

    public private(set) var threads: [MessageThread] = []
    public private(set) var unreadMessageCount: Int = 0
    public private(set) var loadState: LoadState = .idle

    private let repository: any MessagesRepository
    private let fetchUnreadCount: FetchUnreadCountUseCase
    private let fetchThreads: FetchMessageThreadsUseCase
    private let markAllRead: MarkMessagesReadUseCase

    public init(repository: any MessagesRepository) {
        self.repository = repository
        fetchUnreadCount = FetchUnreadCountUseCase(repository: repository)
        fetchThreads = FetchMessageThreadsUseCase(repository: repository)
        markAllRead = MarkMessagesReadUseCase(repository: repository)
    }

    public func conversationViewModel(for thread: MessageThread) -> ConversationViewModel {
        ConversationViewModel(repository: repository, thread: thread)
    }

    public func thread(for threadID: MessageThreadID) -> MessageThread? {
        threads.first { $0.threadID == threadID }
    }

    public func load() async {
        loadState = .loading
        do {
            async let unread = fetchUnreadCount()
            async let inbox = fetchThreads()
            unreadMessageCount = try await unread
            threads = try await inbox
            loadState = threads.isEmpty ? .empty : .loaded
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }

    public func markMessagesRead() async {
        do {
            try await markAllRead()
            unreadMessageCount = 0
            threads = threads.map { thread in
                MessageThread(
                    threadID: thread.threadID,
                    peerDisplayName: thread.peerDisplayName,
                    lastMessagePreview: thread.lastMessagePreview,
                    lastActivityAt: thread.lastActivityAt,
                    unreadCount: 0
                )
            }
        } catch is CancellationError {
            return
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
