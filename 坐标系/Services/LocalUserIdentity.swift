//
//  LocalUserIdentity.swift
//  坐标系
//
//  本机稳定用户 UUID：游客与登录用户共用同一本地身份，登录/登出不更换。
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

    /// 确保已分配 UUID（启动时调用）。
    @discardableResult
    static func ensure() -> UUID { current }

    /// 彻底注销本机账号后重新分配（登出、访客切换登录不调用）。
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
