//
//  LocalUserIdentity.swift
//  坐标系
//
//  本机稳定用户 UUID：游客与登录用户共用；远程登录成功后采用服务端 `user.id`。
//

import Foundation

enum LocalUserIdentity {
    private static let key = "identity.localUserID"

    /// 当前本机用户 UUID。首次访问时生成并持久化。
    static var current: UUID {
        if let stored = UserDefaults.standard.string(forKey: key),
           let id = UUID(uuidString: stored) {
            return id
        }
        return createAndStore()
    }

    @discardableResult
    static func ensure() -> UUID { current }

    /// 远程登录成功后对齐服务端用户 ID。
    static func adopt(_ id: UUID) {
        UserDefaults.standard.set(id.uuidString, forKey: key)
    }

    @discardableResult
    static func regenerate() -> UUID {
        UserDefaults.standard.removeObject(forKey: key)
        return createAndStore()
    }

    private static func createAndStore() -> UUID {
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }
}
