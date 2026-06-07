// Module: SparkAppShell — Joins activity signup with Messages group threads.

import Foundation
import SparkActivity
import SparkMessages

@MainActor
public struct ActivityGroupChatCoordinator {
    private let orchestrator: SparkTabOrchestrator
    private let reloadInbox: () async -> Void
    private let openThread: (String) -> Void

    public init(
        orchestrator: SparkTabOrchestrator,
        reloadInbox: @escaping () async -> Void,
        openThread: @escaping (String) -> Void
    ) {
        self.orchestrator = orchestrator
        self.reloadInbox = reloadInbox
        self.openThread = openThread
    }

    public func onRSVPCompleted(_ detail: ActivityDetail) async {
        guard detail.rsvpStatus.hasGroupChatAccess else { return }
        await provisionGroupChat(for: detail)
    }

    public func openGroupChat(for detail: ActivityDetail) async {
        guard detail.rsvpStatus.hasGroupChatAccess,
              let threadID = detail.conversationThreadID else {
            return
        }
        await provisionGroupChat(for: detail)
        await reloadInbox()
        openThread(threadID)
    }

    public func postRescheduleNotice(for detail: ActivityDetail) async {
        guard let threadID = detail.conversationThreadID else { return }
        await provisionGroupChat(for: detail)
        let body = ActivityAnnounceCopy.rescheduleMessage(
            activityTitle: detail.title,
            scheduleLine: detail.scheduleLine
        )
        // REASONING: Reschedule notice is best-effort; inbox still reloads if send fails offline.
        try? await orchestrator.sendGroupChatMessage(threadID: MessageThreadID(threadID), body: body)
        await reloadInbox()
    }

    public func postHostAnnounce(for detail: ActivityDetail, message: String) async {
        guard let threadID = detail.conversationThreadID else { return }
        await provisionGroupChat(for: detail)
        let body = ActivityAnnounceCopy.systemMessage(activityTitle: detail.title, body: message)
        // REASONING: Host announce is best-effort; user already saw the compose UI succeed locally.
        try? await orchestrator.sendGroupChatMessage(threadID: MessageThreadID(threadID), body: body)
        await reloadInbox()
    }

    private func provisionGroupChat(for detail: ActivityDetail) async {
        guard let threadID = detail.conversationThreadID else { return }
        let displayName = ActivityGroupChatCopy.displayName(activityTitle: detail.title)
        let welcome = ActivityGroupChatCopy.welcomeMessage(activityTitle: detail.title)
        // REASONING: Thread provisioning is idempotent; failure should not block RSVP navigation.
        try? await orchestrator.ensureActivityGroupThread(
            threadID: MessageThreadID(threadID),
            displayName: displayName,
            welcomeMessage: welcome
        )
    }
}
