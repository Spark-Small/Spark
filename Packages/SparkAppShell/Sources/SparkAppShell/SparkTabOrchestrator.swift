// Module: SparkAppShell — Cross-tab orchestration via Coordinators (no Repository leakage).

import SparkActivity
import SparkCore
import SparkLikes
import SparkMessages

public struct SparkTabOrchestrator: Sendable {
    private let messagesCoordinator: MessagesCoordinator
    private let activityCoordinator: ActivityCoordinator
    private let likesCoordinator: LikesCoordinator

    public init(
        messagesCoordinator: MessagesCoordinator,
        activityCoordinator: ActivityCoordinator,
        likesCoordinator: LikesCoordinator
    ) {
        self.messagesCoordinator = messagesCoordinator
        self.activityCoordinator = activityCoordinator
        self.likesCoordinator = likesCoordinator
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

    public func fetchActivityRecap(activityID: String) async -> (title: String, scheduleLine: String)? {
        await activityCoordinator.fetchActivityRecap(activityID: activityID)
    }

    public func submitCommunityLike(userID: String) async {
        _ = try? await likesCoordinator.submitLike(
            SendLikeRequest(userID: UserID(userID), intensity: .like)
        )
    }

    public func syncPremiumEntitlement(isActive: Bool) async {
        try? await likesCoordinator.syncPremiumEntitlement(isActive: isActive)
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
