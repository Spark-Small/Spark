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

    /// 未分组 + 预设 + 自建目录 + 已分配组名（保序去重）。
    var availableFriendGroups: [String] {
        var seen = Set<String>()
        var result: [String] = []

        func append(_ raw: String) {
            let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            let key = value.lowercased()
            guard seen.insert(key).inserted else { return }
            result.append(value)
        }

        append(MessagesCopy.friendGroupUngrouped)
        MessagesCopy.friendGroupPresets.forEach(append)
        friendGroupCatalog.forEach(append)
        friendGroups.values.forEach(append)
        return result
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
            ensureFriendGroupCatalogContains(trimmed, persistAfter: false)
        }
        persist()
    }

    /// 新建分组并可选立即分配给好友。空名 / 「未分组」失败；已存在则只做分配。
    @discardableResult
    func addFriendGroup(_ name: String, assignTo nickname: String? = nil) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != MessagesCopy.friendGroupUngrouped else { return false }
        ensureFriendGroupCatalogContains(trimmed, persistAfter: false)
        if let nickname {
            setGroup(trimmed, for: nickname)
        } else {
            persist()
        }
        return true
    }

    /// 是否可从目录删除（非「未分组」、非预设）。
    func canRemoveFriendGroup(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != MessagesCopy.friendGroupUngrouped else { return false }
        let key = trimmed.lowercased()
        if MessagesCopy.friendGroupPresets.contains(where: { $0.lowercased() == key }) {
            return false
        }
        return friendGroupCatalog.contains { $0.lowercased() == key }
            || friendGroups.values.contains { $0.lowercased() == key }
    }

    /// 删除自建分组：目录移除，已分配好友回退未分组。
    func removeFriendGroup(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canRemoveFriendGroup(trimmed) else { return }
        let key = trimmed.lowercased()
        friendGroupCatalog.removeAll { $0.lowercased() == key }
        for (friendKey, value) in friendGroups where value.lowercased() == key {
            friendGroups.removeValue(forKey: friendKey)
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

    private func ensureFriendGroupCatalogContains(_ name: String, persistAfter: Bool) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != MessagesCopy.friendGroupUngrouped else { return }
        let key = trimmed.lowercased()
        if MessagesCopy.friendGroupPresets.contains(where: { $0.lowercased() == key }) {
            return
        }
        if friendGroupCatalog.contains(where: { $0.lowercased() == key }) {
            return
        }
        friendGroupCatalog.append(trimmed)
        if persistAfter { persist() }
    }
}
