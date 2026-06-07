// Module: SparkMessages — Single-thread conversation state.

import Foundation
import Observation
import SparkCore

@MainActor
@Observable
public final class ConversationViewModel {
    private enum Limits {
        static let maxMessageLength = 2000
    }

    private static let logger = SparkLog.logger(category: "Messages.Conversation")

    public enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failure(String)
    }

    public let thread: MessageThread
    public private(set) var messages: [ChatMessage] = []
    public private(set) var context: ConversationContext?
    public private(set) var loadState: LoadState = .idle
    public var draftText: String = ""
    public private(set) var isSending = false
    /// Increments after a successful send; drives composer haptic feedback.
    public private(set) var sendSuccessToken = 0
    public private(set) var sendErrorMessage: String?

    public var isGroupChat: Bool { thread.threadID.isGroupChat }
    public var isDirectMessage: Bool { thread.threadID.isDirectMessage }

    public var groupBannerActivity: InboxActivitySummary? {
        guard isGroupChat else { return nil }
        for message in messages {
            if let payload = message.systemPayload, let activityID = payload.ctaActivityID {
                return InboxActivitySummary(
                    id: activityID,
                    title: payload.title,
                    startsAt: Date().addingTimeInterval(86_400),
                    attendeeCount: 0
                )
            }
            if let activityID = message.activityID {
                return InboxActivitySummary(
                    id: activityID,
                    title: thread.peerDisplayName,
                    startsAt: Date().addingTimeInterval(86_400),
                    attendeeCount: 0
                )
            }
        }
        return nil
    }

    private let fetchMessages: any FetchThreadMessagesUseCaseProtocol
    private let fetchContext: any FetchConversationContextUseCaseProtocol
    private let sendMessage: any SendThreadMessageUseCaseProtocol

    public init(
        fetchMessages: any FetchThreadMessagesUseCaseProtocol,
        fetchContext: any FetchConversationContextUseCaseProtocol,
        sendMessage: any SendThreadMessageUseCaseProtocol,
        thread: MessageThread
    ) {
        self.thread = thread
        self.fetchMessages = fetchMessages
        self.fetchContext = fetchContext
        self.sendMessage = sendMessage
    }

    public convenience init(repository: any MessagesRepository, thread: MessageThread) {
        self.init(
            fetchMessages: FetchThreadMessagesUseCase(repository: repository),
            fetchContext: FetchConversationContextUseCase(repository: repository),
            sendMessage: SendThreadMessageUseCase(repository: repository),
            thread: thread
        )
    }

    public func load() async {
        loadState = .loading
        do {
            async let loadedMessages = fetchMessages(threadID: thread.threadID)
            async let loadedContext = fetchContext(threadID: thread.threadID)
            messages = try await loadedMessages
            context = try await loadedContext
            loadState = .loaded
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("load conversation failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.errorDescription ?? "")
        } catch {
            Self.logger.error("load conversation failed: \(error.localizedDescription, privacy: .public)")
            loadState = .failure(error.localizedDescription)
        }
    }

    public func sendTapped() async {
        let text = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        guard text.count <= Limits.maxMessageLength else {
            sendErrorMessage = String(
                localized: "messages.composer.tooLong",
                defaultValue: "消息过长，请缩短后再发送",
                comment: "Message too long"
            )
            return
        }
        isSending = true
        sendErrorMessage = nil
        defer { isSending = false }
        do {
            let message = try await sendMessage(threadID: thread.threadID, body: text)
            messages.append(message)
            draftText = ""
            sendSuccessToken += 1
            if isGroupChat, let activityID = thread.threadID.activityGroupActivityID {
                IntegrationTelemetry.groupMessageAfterRSVP(activityID: activityID)
            }
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("send message failed: \(error.localizedDescription, privacy: .public)")
            sendErrorMessage = error.errorDescription
        } catch {
            Self.logger.error("send message failed: \(error.localizedDescription, privacy: .public)")
            sendErrorMessage = error.localizedDescription
        }
    }
}
