// Module: SparkMessagesTests — Mock repository integration for Data layer coverage.

@testable import SparkMessages
import Testing

struct MessagesMockRepositoryIntegrationTests {
    @Test func mockRepositoryExercisesAllOperations() async throws {
        let repository = MockMessagesRepository()

        _ = try await repository.fetchUnreadCount()
        let threads = try await repository.fetchThreads()
        #expect(!threads.isEmpty)
        let inbox = try await repository.fetchInbox()
        #expect(!inbox.actionItems.isEmpty)

        let threadID = try #require(threads.first?.threadID)
        _ = try await repository.fetchMessages(threadID: threadID)
        _ = try await repository.fetchConversationContext(threadID: threadID)
        _ = try await repository.sendMessage(threadID: threadID, body: "Integration ping")
        try await repository.markAllRead()
        try await repository.markThreadRead(threadID: threadID)

        if let item = inbox.actionItems.first(where: {
            if case .activityInvite = $0.kind { return true }
            return false
        }), case .activityInvite(let invite) = item.kind {
            try await repository.respondToActivityInvite(
                activityID: invite.activity.id,
                invitationID: invite.id,
                accept: false
            )
        }

        if let actionID = inbox.actionItems.first?.id {
            try await repository.dismissInboxActionItem(id: actionID)
        }

        _ = try await repository.ensureDirectMessageThread(peerUserID: "u_li", peerDisplayName: "Li")
        try await repository.ensureActivityGroupThread(
            threadID: MessageThreadID("th_grp_act_1"),
            displayName: "Hike group",
            welcomeMessage: "Welcome"
        )
    }
}
