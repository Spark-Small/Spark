//
//  InterestCustomTagPlacementStore.swift
//  坐标系
//
//  自定义喜好标签所属分区（catalog 外）：本机 UserDefaults，登出 / 删号清理。
//

import Foundation

enum InterestCustomTagPlacementStore {
    private static let keyPrefix = "profile.interestCustomPlacement."

    private static func key(for userID: UUID) -> String {
        keyPrefix + userID.uuidString
    }

    static func load(userID: UUID = LocalUserIdentity.current) -> [String: String] {
        guard let stored = UserDefaults.standard.dictionary(forKey: key(for: userID)) as? [String: String]
        else { return [:] }
        return stored.filter { !$0.key.isEmpty && !$0.value.isEmpty }
    }

    static func save(_ placement: [String: String], userID: UUID = LocalUserIdentity.current) {
        let normalized = Dictionary(
            uniqueKeysWithValues: placement
                .map { (
                    $0.key.trimmingCharacters(in: .whitespacesAndNewlines),
                    $0.value.trimmingCharacters(in: .whitespacesAndNewlines)
                ) }
                .filter { !$0.0.isEmpty && !$0.1.isEmpty }
        )
        if normalized.isEmpty {
            clear(userID: userID)
            return
        }
        UserDefaults.standard.set(normalized, forKey: key(for: userID))
    }

    static func clear(userID: UUID = LocalUserIdentity.current) {
        UserDefaults.standard.removeObject(forKey: key(for: userID))
    }
}
