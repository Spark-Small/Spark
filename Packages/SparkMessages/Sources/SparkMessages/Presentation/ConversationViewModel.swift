// Module: SparkMessages — Single-thread conversation state.

import Foundation
import Observation

@MainActor
@Observable
public final class ConversationViewModel {
    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public let thread: MessageThread
    public private(set) var messages: [ChatMessage] = []
    public private(set) var loadState: LoadState = .idle
    public var draftText: String = ""
    public private(set) var isSending = false

    private let fetchMessages: FetchThreadMessagesUseCase
    private let sendMessage: SendThreadMessageUseCase

    public init(repository: any MessagesRepository, thread: MessageThread) {
        self.thread = thread
        fetchMessages = FetchThreadMessagesUseCase(repository: repository)
        sendMessage = SendThreadMessageUseCase(repository: repository)
    }

    public func load() async {
        loadState = .loading
        do {
            messages = try await fetchMessages(threadID: thread.threadID)
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }

    public func sendTapped() async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        isSending = true
        defer { isSending = false }
        do {
            let message = try await sendMessage(threadID: thread.threadID, body: text)
            messages.append(message)
            draftText = ""
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            loadState = .failure(error.localizedDescription)
        }
    }
}
