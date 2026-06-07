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
    public let dmPartner: InboxUserProfile?
    public let groupActivity: InboxActivitySummary?
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

    public var peerUserID: String? {
        dmPartner?.id ?? thread.threadID.directMessagePeerUserID
    }

    public var resolvedDisplayName: String {
        if let peerUserID {
            let fallback = dmPartner?.displayName ?? thread.peerDisplayName
            return peerDisplayNameStore.resolvedDisplayName(userID: peerUserID, fallback: fallback)
        }
        return thread.peerDisplayName
    }

    public var groupBannerActivity: InboxActivitySummary? {
        if let groupActivity { return groupActivity }
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
    private let peerDisplayNameStore: PeerDisplayNameStore

    public init(
        fetchMessages: any FetchThreadMessagesUseCaseProtocol,
        fetchContext: any FetchConversationContextUseCaseProtocol,
        sendMessage: any SendThreadMessageUseCaseProtocol,
        thread: MessageThread,
        dmPartner: InboxUserProfile? = nil,
        groupActivity: InboxActivitySummary? = nil,
        peerDisplayNameStore: PeerDisplayNameStore
    ) {
        self.thread = thread
        self.dmPartner = dmPartner
        self.groupActivity = groupActivity
        self.peerDisplayNameStore = peerDisplayNameStore
        self.fetchMessages = fetchMessages
        self.fetchContext = fetchContext
        self.sendMessage = sendMessage
    }

    public convenience init(
        repository: any MessagesRepository,
        thread: MessageThread,
        peerDisplayNameStore: PeerDisplayNameStore = PeerDisplayNameStore(storage: InMemoryPeerDisplayNameStore())
    ) {
        self.init(
            fetchMessages: FetchThreadMessagesUseCase(repository: repository),
            fetchContext: FetchConversationContextUseCase(repository: repository),
            sendMessage: SendThreadMessageUseCase(repository: repository),
            thread: thread,
            peerDisplayNameStore: peerDisplayNameStore
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
            let message = try await sendMessage(threadID: thread.threadID, body: text, kind: .text)
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

    public func sendImage(_ imageData: Data) async {
        guard !isSending else { return }
        isSending = true
        sendErrorMessage = nil
        defer { isSending = false }
        do {
            let fileURL = try writeTemporaryImage(data: imageData)
            let message = try await sendMessage(
                threadID: thread.threadID,
                body: fileURL.absoluteString,
                kind: .image
            )
            messages.append(message)
            sendSuccessToken += 1
        } catch is CancellationError {
            return
        } catch let error as MessagesError {
            Self.logger.error("send image failed: \(error.localizedDescription, privacy: .public)")
            sendErrorMessage = error.errorDescription
        } catch {
            Self.logger.error("send image failed: \(error.localizedDescription, privacy: .public)")
            sendErrorMessage = error.localizedDescription
        }
    }

    private func writeTemporaryImage(data: Data) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let url = directory.appendingPathComponent("spark-msg-\(UUID().uuidString).jpg")
        try data.write(to: url, options: .atomic)
        return url
    }
}
