//
//  BuddyIdentityMatching.swift
//  CoordinateDomain
//
//  搭子身份匹配：优先稳定 userID，缺省回退昵称。
//

import Foundation

public enum BuddyIdentityMatching: Sendable {
    /// 两边都有 userID 时只比 ID；否则昵称大小写不敏感比较。
    public static func matches(
        nickname lhsName: String,
        userID lhsID: UUID?,
        otherNickname rhsName: String,
        otherUserID rhsID: UUID?
    ) -> Bool {
        if let lhsID, let rhsID {
            return lhsID == rhsID
        }
        return lhsName.caseInsensitiveCompare(rhsName) == .orderedSame
    }

    /// 演示/种子：由昵称派生稳定 UUID（跨启动一致，非加密）。
    public static func stableUserID(forNickname nickname: String) -> UUID {
        let normalized = nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var bytes = [UInt8](repeating: 0, count: 16)
        let utf8 = Array(normalized.utf8)
        guard !utf8.isEmpty else {
            return UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
        }
        for (index, byte) in utf8.enumerated() {
            bytes[index % 16] ^= byte &+ UInt8(index % 251)
            bytes[(index &* 3) % 16] &+= byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
