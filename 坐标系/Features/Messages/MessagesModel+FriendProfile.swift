//
//  MessagesModel+FriendProfile.swift
//  坐标系
//

import CoordinateDomain
import Foundation
import Observation

extension MessagesModel {
    func declineFriendRequest(_ id: FriendRequest.ID) {
        guard let idx = friendRequests.firstIndex(where: { $0.id == id }) else { return }
        friendRequests[idx].status = .declined
        persist()
    }

    /// 按昵称删除好友会话（拉黑时调用）
    func deleteDirectChat(with nickname: String) {
        let name = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let ids = conversations
            .filter { $0.kind == .direct && $0.title.caseInsensitiveCompare(name) == .orderedSame }
            .map(\.id)
        ids.forEach { id in
            conversations.removeAll { $0.id == id }
            threads[id] = nil
            groupMembersByConversation[id] = nil
        }
        transferRecords.removeAll { ids.contains($0.conversationID) }
        callRecords.removeAll { ids.contains($0.conversationID) }
        clearFriendProfile(for: name, persistAfter: false)
        persist()
    }

    func remark(for nickname: String) -> String {
        friendRemarks[Self.friendKey(nickname)] ?? ""
    }

    func group(for nickname: String) -> String {
        let value = friendGroups[Self.friendKey(nickname)] ?? ""
        return value.isEmpty ? MessagesCopy.friendGroupUngrouped : value
    }

    func displayName(for nickname: String) -> String {
        let remark = remark(for: nickname).trimmingCharacters(in: .whitespacesAndNewlines)
        return remark.isEmpty ? nickname : remark
    }

    func setRemark(_ remark: String, for nickname: String) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        let trimmed = remark.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            friendRemarks.removeValue(forKey: key)
        } else {
            friendRemarks[key] = trimmed
        }
        persist()
    }

    func setGroup(_ group: String, for nickname: String) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        let trimmed = group.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == MessagesCopy.friendGroupUngrouped {
            friendGroups.removeValue(forKey: key)
        } else {
            friendGroups[key] = trimmed
        }
        persist()
    }

    /// 删除好友：清会话与备注/分组
    func deleteFriend(named nickname: String) {
        deleteDirectChat(with: nickname)
    }

    func clearFriendProfile(for nickname: String, persistAfter: Bool = true) {
        let key = Self.friendKey(nickname)
        guard !key.isEmpty else { return }
        friendRemarks.removeValue(forKey: key)
        friendGroups.removeValue(forKey: key)
        if persistAfter { persist() }
    }

    static func friendKey(_ nickname: String) -> String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
