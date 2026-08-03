//
//  LocalAuthSession.swift
//  坐标系
//

import Foundation
import Observation

/// 本机账号身份类型（演示登录；正式版可换真实 OAuth）。
enum LocalAccountProvider: String, Codable, CaseIterable {
    case guest
    case phone
    case apple
    case wechat

    var displayName: String {
        switch self {
        case .guest: "访客"
        case .phone: "手机号"
        case .apple: "Apple"
        case .wechat: "微信"
        }
    }
}

@MainActor
@Observable
final class LocalAuthSession {
    private enum Keys {
        static let signedIn = "auth.isSignedIn"
        static let phone = "auth.phone"
        static let guest = "auth.isGuest"
        static let provider = "auth.provider"
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

    /// 登录渠道；访客为 `.guest`。
    var provider: LocalAccountProvider {
        didSet { UserDefaults.standard.set(provider.rawValue, forKey: Keys.provider) }
    }

    /// 交易 / 资料写入需要非访客账号。
    var requiresAccount: Bool { isGuest || !isSignedIn }

    var accountStatusLabel: String {
        if !isSignedIn { return "未登录" }
        if isGuest { return "访客" }
        return "已登录"
    }

    var loginMethodLabel: String {
        if isGuest || !isSignedIn { return LocalAccountProvider.guest.displayName }
        return provider.displayName
    }

    var maskedPhoneLabel: String {
        let trimmed = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              provider == .phone,
              trimmed.count >= 7
        else { return "—" }
        let prefix = trimmed.prefix(3)
        let suffix = trimmed.suffix(4)
        return "\(prefix)****\(suffix)"
    }

    init() {
        LocalUserIdentity.ensure()
        let signedIn = UserDefaults.standard.bool(forKey: Keys.signedIn)
        let guest = UserDefaults.standard.bool(forKey: Keys.guest)
        let phone = UserDefaults.standard.string(forKey: Keys.phone) ?? ""
        let resolvedProvider: LocalAccountProvider
        if let raw = UserDefaults.standard.string(forKey: Keys.provider),
           let stored = LocalAccountProvider(rawValue: raw) {
            resolvedProvider = stored
        } else {
            resolvedProvider = Self.inferredProvider(isGuest: guest, phone: phone)
        }
        isSignedIn = signedIn
        isGuest = guest
        phoneNumber = phone
        provider = resolvedProvider
    }

    @discardableResult
    func signIn(phone: String, code: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, code == Self.demoCode else { return false }
        LocalUserIdentity.ensure()
        phoneNumber = trimmed
        provider = .phone
        isGuest = false
        isSignedIn = true
        return true
    }

    func signInDemoApple() {
        LocalUserIdentity.ensure()
        if phoneNumber.isEmpty || phoneNumber == "demo.wechat" {
            phoneNumber = "demo.apple"
        }
        provider = .apple
        isGuest = false
        isSignedIn = true
    }

    func signInDemoWeChat() {
        LocalUserIdentity.ensure()
        if phoneNumber.isEmpty || phoneNumber == "demo.apple" {
            phoneNumber = "demo.wechat"
        }
        provider = .wechat
        isGuest = false
        isSignedIn = true
    }

    /// 以访客身份继续：不绑定手机号，保留本机 UUID。
    func continueAsGuest() {
        LocalUserIdentity.ensure()
        phoneNumber = ""
        provider = .guest
        isGuest = true
        isSignedIn = true
    }

    func signOut() {
        isSignedIn = false
        isGuest = false
        provider = .guest
    }

    func resetStoredSession() {
        phoneNumber = ""
        isGuest = false
        isSignedIn = false
        provider = .guest
        UserDefaults.standard.removeObject(forKey: Keys.phone)
        UserDefaults.standard.removeObject(forKey: Keys.signedIn)
        UserDefaults.standard.removeObject(forKey: Keys.guest)
        UserDefaults.standard.removeObject(forKey: Keys.provider)
        LocalUserIdentity.regenerate()
    }

    private static func inferredProvider(isGuest: Bool, phone: String) -> LocalAccountProvider {
        if isGuest { return .guest }
        switch phone {
        case "demo.apple": return .apple
        case "demo.wechat": return .wechat
        case "": return .guest
        default: return .phone
        }
    }
}
