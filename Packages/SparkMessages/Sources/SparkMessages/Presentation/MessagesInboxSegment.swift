// Module: SparkMessages — Inbox segmented pages (DM vs group chats).

import Foundation

enum MessagesInboxSegment: String, CaseIterable, Identifiable, Sendable {
    case dm
    case groupChats

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .dm:
            String(
                localized: "messages.segment.dm",
                defaultValue: "消息",
                comment: "Messages inbox DM segment"
            )
        case .groupChats:
            String(
                localized: "messages.segment.groups",
                defaultValue: "群聊",
                comment: "Messages inbox group chats segment"
            )
        }
    }
}
