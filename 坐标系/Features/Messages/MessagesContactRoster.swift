//
//  MessagesContactRoster.swift
//  坐标系
//
//  通讯录 / 发起聊天 / 群邀请共用的好友昵称来源。
//

import Foundation
import CoordinateModels

enum MessagesContactRoster {
    static func nicknames(
        conversations: [ChatConversation],
        inviteNicknames: [String],
        bookingNicknames: [String],
        blockedNames: [String]
    ) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        func append(_ name: String) {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            let key = trimmed.lowercased()
            guard !key.isEmpty, !seen.contains(key) else { return }
            if blockedNames.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                return
            }
            seen.insert(key)
            result.append(trimmed)
        }

        for conversation in conversations where conversation.isFriendChat && conversation.isFriend && !conversation.isMessageRequest {
            append(conversation.title)
        }
        for name in inviteNicknames { append(name) }
        for name in bookingNicknames { append(name) }

        return result.sorted {
            $0.localizedStandardCompare($1) == .orderedAscending
        }
    }
}
