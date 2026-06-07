// Module: SparkAppShell — Cross-tab orchestration via Coordinators (no Repository leakage).

import SparkActivity
import SparkCore
import SparkMessages

public struct SparkTabOrchestrator: Sendable {
    private let messagesCoordinator: MessagesCoordinator
    private let activityCoordinator: ActivityCoordinator

    public init(
        messagesCoordinator: MessagesCoordinator,
        activityCoordinator: ActivityCoordinator
    ) {
        self.messagesCoordinator = messagesCoordinator
        self.activityCoordinator = activityCoordinator
    }

    public func openMatchConversation(
        threadID: String,
        peerDisplayName: String,
        initialMessage: String?
    ) async -> String {
        let peerUserID = SparkMainTabRouting.peerUserID(fromDirectThreadID: threadID)
        return await messagesCoordinator.openMatchConversation(
            peerUserID: peerUserID,
            peerDisplayName: peerDisplayName,
            fallbackThreadID: threadID,
            initialMessage: initialMessage
        )
    }

    public func fetchRecommendedActivity() async -> (id: String, title: String)? {
        await activityCoordinator.fetchRecommendedActivity()
    }

    public func fetchActivityShareContext(activityID: String) async -> ActivityShareContext? {
        await activityCoordinator.fetchActivityShareContext(activityID: activityID)
    }

    public func syncActivityReminders(for detail: ActivityDetail) async {
        await activityCoordinator.syncReminders(for: detail)
    }

    public func sendGroupChatMessage(threadID: MessageThreadID, body: String) async throws {
        try await messagesCoordinator.sendMessage(threadID: threadID, body: body)
    }

    public func ensureActivityGroupThread(
        threadID: MessageThreadID,
        displayName: String,
        welcomeMessage: String
    ) async throws {
        try await messagesCoordinator.ensureActivityGroupThread(
            threadID: threadID,
            displayName: displayName,
            welcomeMessage: welcomeMessage
        )
    }
}
