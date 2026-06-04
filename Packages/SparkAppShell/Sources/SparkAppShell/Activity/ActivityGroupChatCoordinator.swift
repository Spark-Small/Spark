// Module: SparkAppShell — Joins activity signup with Messages group threads.

import Foundation
import SparkActivity
import SparkMessages

@MainActor
public struct ActivityGroupChatCoordinator {
    private let messagesRepository: any MessagesRepository
    private let reloadInbox: () async -> Void
    private let openThread: (String) -> Void

    public init(
        messagesRepository: any MessagesRepository,
        reloadInbox: @escaping () async -> Void,
        openThread: @escaping (String) -> Void
    ) {
        self.messagesRepository = messagesRepository
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
        try? await messagesRepository.sendMessage(threadID: MessageThreadID(threadID), body: body)
        await reloadInbox()
    }

    public func postHostAnnounce(for detail: ActivityDetail, message: String) async {
        guard let threadID = detail.conversationThreadID else { return }
        await provisionGroupChat(for: detail)
        let body = ActivityAnnounceCopy.systemMessage(activityTitle: detail.title, body: message)
        try? await messagesRepository.sendMessage(threadID: MessageThreadID(threadID), body: body)
        await reloadInbox()
    }

    private func provisionGroupChat(for detail: ActivityDetail) async {
        guard let threadID = detail.conversationThreadID else { return }
        let displayName = ActivityGroupChatCopy.displayName(activityTitle: detail.title)
        let welcome = ActivityGroupChatCopy.welcomeMessage(activityTitle: detail.title)
        try? await messagesRepository.ensureActivityGroupThread(
            threadID: MessageThreadID(threadID),
            displayName: displayName,
            welcomeMessage: welcome
        )
    }
}
