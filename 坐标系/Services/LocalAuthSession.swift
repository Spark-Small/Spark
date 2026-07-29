//
//  LocalAuthSession.swift
//  坐标系
//

import Foundation
import Observation

@MainActor
@Observable
final class LocalAuthSession {
    private enum Keys {
        static let signedIn = "auth.isSignedIn"
        static let phone = "auth.phone"
        static let guest = "auth.isGuest"
    }

    static let demoCode = "123456"

    /// 本机用户 UUID（游客与登录用户共用）。
    var localUserID: UUID { LocalUserIdentity.current }

    var isSignedIn: Bool {
        didSet { UserDefaults.standard.set(isSignedIn, forKey: Keys.signedIn) }
    }

    /// 访客模式：可进入应用，但仍有稳定 UUID。
    var isGuest: Bool {
        didSet { UserDefaults.standard.set(isGuest, forKey: Keys.guest) }
    }

    var phoneNumber: String {
        didSet { UserDefaults.standard.set(phoneNumber, forKey: Keys.phone) }
    }

    init() {
        LocalUserIdentity.ensure()
        isSignedIn = UserDefaults.standard.bool(forKey: Keys.signedIn)
        isGuest = UserDefaults.standard.bool(forKey: Keys.guest)
        phoneNumber = UserDefaults.standard.string(forKey: Keys.phone) ?? ""
    }

    @discardableResult
    func signIn(phone: String, code: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, code == Self.demoCode else { return false }
        LocalUserIdentity.ensure()
        phoneNumber = trimmed
        isGuest = false
        isSignedIn = true
        return true
    }

    func signInDemoApple() {
        LocalUserIdentity.ensure()
        phoneNumber = phoneNumber.isEmpty ? "demo.apple" : phoneNumber
        isGuest = false
        isSignedIn = true
    }

    func signInDemoWeChat() {
        LocalUserIdentity.ensure()
        phoneNumber = phoneNumber.isEmpty ? "demo.wechat" : phoneNumber
        isGuest = false
        isSignedIn = true
    }

    /// 以访客身份继续：不绑定手机号，保留本机 UUID。
    func continueAsGuest() {
        LocalUserIdentity.ensure()
        phoneNumber = ""
        isGuest = true
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        isGuest = false
    }

    func resetStoredSession() {
        phoneNumber = ""
        isGuest = false
        isSignedIn = false
        UserDefaults.standard.removeObject(forKey: Keys.phone)
        UserDefaults.standard.removeObject(forKey: Keys.signedIn)
        UserDefaults.standard.removeObject(forKey: Keys.guest)
        LocalUserIdentity.regenerate()
    }
}
