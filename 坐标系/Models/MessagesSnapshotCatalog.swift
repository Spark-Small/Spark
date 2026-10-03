//
//  MessagesSnapshotCatalog.swift
//  坐标系
//

import CoordinateData
import CoordinateModels
import Foundation

enum MessagesSnapshotCatalog {
    /// 保留已有会话线程，仅补齐缺失的种子会话并清理孤儿引用。
    static func repair(from previous: MessagesSnapshot) -> MessagesSnapshot {
        let seed = MessagesSnapshot.seed

        var seenConversationIDs = Set<UUID>()
        var conversations: [ChatConversation] = []
        for conversation in previous.conversations where seenConversationIDs.insert(conversation.id).inserted {
            conversations.append(conversation)
        }

        #if DEBUG
        let existingConversationIDs = Set(conversations.map(\.id))
        for conversation in seed.conversations where !existingConversationIDs.contains(conversation.id) {
            conversations.append(conversation)
        }
        #endif

        let conversationKinds = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0.kind) })
        let validConversationIDs = Set(conversations.map(\.id))

        var threads: [String: [ChatMessage]] = [:]
        for conversation in conversations {
            let key = conversation.id.uuidString
            if let existing = previous.threads[key] {
                threads[key] = existing
            } else if let seeded = seed.threads[key] {
                threads[key] = seeded
            } else {
                threads[key] = []
            }
        }

        let groupMembers: [String: [GroupMemberRecord]] = Dictionary(
            uniqueKeysWithValues: previous.groupMembers.compactMap { key, members in
                guard let id = UUID(uuidString: key),
                      validConversationIDs.contains(id),
                      conversationKinds[id] == .group
                else { return nil }
                return (key, members)
            }
        )

        var seenRequestIDs = Set<UUID>()
        let repairedRequests = previous.friendRequests
            .sorted { $0.createdAt > $1.createdAt }
            .filter { seenRequestIDs.insert($0.id).inserted }

        let repairedRemarks = normalizedFriendMetadata(previous.friendRemarks)
        let repairedGroups = normalizedFriendMetadata(previous.friendGroups)
        let repairedCatalog = normalizedFriendGroupCatalog(
            previous.friendGroupCatalog,
            assignedGroups: repairedGroups.values
        )
        let repairedTransfers = previous.transferRecords.filter { validConversationIDs.contains($0.conversationID) }
        let repairedCalls = previous.callRecords.filter { validConversationIDs.contains($0.conversationID) }

        var seenOutgoingIDs = Set<UUID>()
        let repairedOutgoing = previous.outgoingFriendRequests
            .sorted { $0.createdAt > $1.createdAt }
            .filter { seenOutgoingIDs.insert($0.id).inserted }

        return MessagesSnapshot(
            conversations: conversations,
            threads: threads,
            friendRequests: repairedRequests,
            outgoingFriendRequests: repairedOutgoing,
            friendRemarks: repairedRemarks,
            friendGroups: repairedGroups,
            friendGroupCatalog: repairedCatalog,
            groupMembers: groupMembers,
            transferRecords: repairedTransfers,
            callRecords: repairedCalls
        )
    }

    private static func normalizedFriendMetadata(_ source: [String: String]) -> [String: String] {
        var normalized: [String: String] = [:]
        for (rawKey, rawValue) in source {
            let key = rawKey.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty, !value.isEmpty else { continue }
            normalized[key] = value
        }
        return normalized
    }

    /// 保序去重；把已分配但未入库的自建组名补进目录；排除空串。
    /// 「未分组」与预设名可出现在赋值里，目录侧去重后由 Model 再与预设合并。
    private static func normalizedFriendGroupCatalog(
        _ source: [String],
        assignedGroups: Dictionary<String, String>.Values
    ) -> [String] {
        var seen = Set<String>()
        var catalog: [String] = []

        func append(_ raw: String) {
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            let key = value.lowercased()
            // 与 MessagesCopy.friendGroupUngrouped / friendGroupPresets 对齐的产品字面量
            let reserved: Set<String> = ["未分组", "亲密好友", "同事", "同学", "其他"]
            guard !reserved.contains(key) else { return }
            guard seen.insert(key).inserted else { return }
            catalog.append(value)
        }

        source.forEach(append)
        assignedGroups.forEach(append)
        return catalog
    }
}

struct AppMessagesSnapshotPolicy: MessagesSnapshotPersistencePolicy {
    func fallbackSnapshot() -> MessagesSnapshot { .seed }

    func afterLoad(_ loaded: MessagesSnapshot) -> (snapshot: MessagesSnapshot, shouldPersist: Bool) {
        let repaired = MessagesSnapshotCatalog.repair(from: loaded)
        return (repaired, !SnapshotCodableCompare.equal(loaded, repaired))
    }
}
