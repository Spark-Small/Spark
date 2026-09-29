//
//  UserPublicID.swift
//  坐标系
//
//  对外数字 UID（米哈游风格）：由 UUID / 昵称稳定派生，内部仍用 UUID 主键。
//

import Foundation
import CoordinateModels

enum UserPublicID {
    static let digitCount = 9

    /// 由本机 UUID 派生的 9 位数字 UID（100000000…999999999）。
    static func code(for id: UUID) -> String {
        let bytes = withUnsafeBytes(of: id.uuid) { Array($0) }
        var value: UInt64 = 0
        for index in 0..<8 {
            value = (value << 8) | UInt64(bytes[index])
        }
        return format(100_000_000 + value % 900_000_000)
    }

    /// 无 UUID 时（纯昵称好友）用昵称稳定派生。
    static func code(forNickname name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in trimmed.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        return format(100_000_000 + hash % 900_000_000)
    }

    static func code(profileID: UUID, nickname: String) -> String {
        _ = nickname
        return code(for: profileID)
    }

    static func normalize(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    static func isValid(_ raw: String) -> Bool {
        normalize(raw).count == digitCount
    }

    static func formatDisplay(_ raw: String) -> String {
        let digits = normalize(raw)
        guard digits.count == digitCount else { return digits }
        let i3 = digits.index(digits.startIndex, offsetBy: 3)
        let i6 = digits.index(digits.startIndex, offsetBy: 6)
        return "\(digits[..<i3]) \(digits[i3..<i6]) \(digits[i6...])"
    }

    private static func format(_ value: UInt64) -> String {
        String(format: "%09d", value)
    }
}

struct UserPublicDirectoryHit: Equatable {
    let uid: String
    let nickname: String
    let isSelf: Bool
}

@MainActor
enum UserPublicDirectory {
    /// 用数字 UID 查找可添加的演示用户（搭子种子 + 常见昵称）。
    static func resolve(rawUID: String, myUser: AppUser) -> UserPublicDirectoryHit? {
        let uid = UserPublicID.normalize(rawUID)
        guard UserPublicID.isValid(uid) else { return nil }

        let myUID = UserPublicID.code(for: myUser.id)
        if uid == myUID {
            return UserPublicDirectoryHit(uid: uid, nickname: myUser.name, isSelf: true)
        }

        for buddy in SampleData.circleBuddies {
            if UserPublicID.code(for: buddy.profile.id) == uid {
                return UserPublicDirectoryHit(
                    uid: uid,
                    nickname: buddy.profile.nickname,
                    isSelf: false
                )
            }
        }
        for companion in SampleData.paidCompanions {
            if UserPublicID.code(for: companion.profile.id) == uid {
                return UserPublicDirectoryHit(
                    uid: uid,
                    nickname: companion.profile.nickname,
                    isSelf: false
                )
            }
        }

        for name in demoNicknameRoster where UserPublicID.code(forNickname: name) == uid {
            return UserPublicDirectoryHit(uid: uid, nickname: name, isSelf: false)
        }

        return nil
    }

    static func uid(forNickname name: String) -> String {
        if let buddy = SampleData.circleBuddies.first(where: {
            $0.profile.nickname.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return UserPublicID.code(for: buddy.profile.id)
        }
        if let companion = SampleData.paidCompanions.first(where: {
            $0.profile.nickname.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return UserPublicID.code(for: companion.profile.id)
        }
        return UserPublicID.code(forNickname: name)
    }

    private static var demoNicknameRoster: [String] {
        var names = Set<String>()
        SampleData.friendRequests.forEach { names.insert($0.fromName) }
        // 种子会话里常见的好友昵称
        ["阿凯", "林夏", "Coco", "阿哲", "Mia", "Leo", "小满"].forEach { names.insert($0) }
        return Array(names)
    }
}

extension AppUser {
    var publicUID: String { UserPublicID.code(for: id) }

    var publicUIDDisplay: String { UserPublicID.formatDisplay(publicUID) }
}
