//
//  InterestSelectionDraftStore.swift
//  坐标系
//
//  兴趣引导中途草稿：UserDefaults 暂存，完成 / 登出时清理（Apple 偏好类短草稿惯例）。
//

import Foundation

enum InterestSelectionDraftStore {
    private static let keyPrefix = "onboarding.interestDraft."

    private static func key(for userID: UUID) -> String {
        keyPrefix + userID.uuidString
    }

    static func load(userID: UUID = LocalUserIdentity.current) -> [String]? {
        guard let stored = UserDefaults.standard.array(forKey: key(for: userID)) as? [String],
              !stored.isEmpty
        else { return nil }
        return stored
    }

    static func save(_ interests: [String], userID: UUID = LocalUserIdentity.current) {
        let normalized = Array(Set(interests.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }))
            .filter { !$0.isEmpty }
            .sorted()
        if normalized.isEmpty {
            clear(userID: userID)
            return
        }
        UserDefaults.standard.set(normalized, forKey: key(for: userID))
    }

    static func clear(userID: UUID = LocalUserIdentity.current) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }

    /// 登出 / 删号 / 重置：草稿 + 自定义标签分区一并清理。
    static func clearSessionStores(userID: UUID = LocalUserIdentity.current) {
        clear(userID: userID)
        InterestCustomTagPlacementStore.clear(userID: userID)
    }
}
