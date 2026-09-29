//
//  LocalAuthSession.swift
//  坐标系
//

import Foundation
import Observation
import CoordinateModels
import CoordinateNetworking
import CoordinateFeatureFlags

/// 本机账号身份类型。
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

    /// 仅 DEBUG 本地短信演示码；Release 必须走远程验证码。
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

    /// 本地演示短信登录（仅 DEBUG）。
    @discardableResult
    func signIn(phone: String, code: String) -> Bool {
        #if DEBUG
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8, code == Self.demoCode else { return false }
        applySignedIn(phone: trimmed, provider: .phone)
        return true
        #else
        return false
        #endif
    }

    /// 远端短信登录（Release 默认；DEBUG 由 `useRemoteAuth` 控制）。
    @discardableResult
    func signInRemote(phone: String, code: String) async -> String? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return "手机号格式不正确" }
        do {
            _ = try await RemoteAuthAPI.loginSMS(phone: trimmed, code: code)
            applySignedIn(phone: trimmed, provider: .phone)
            return nil
        } catch let error as APIError {
            return error.localizedDescription
        } catch {
            return error.localizedDescription
        }
    }

    /// 发送短信验证码（远程）。
    @discardableResult
    func sendRemoteSMSCode(phone: String) async -> String? {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 8 else { return "手机号格式不正确" }
        do {
            let data = try await RemoteAuthAPI.sendSMS(phone: trimmed)
            #if DEBUG
            if let dev = data.devCode, !dev.isEmpty {
                return nil // 成功；dev_code 由 UI footer 提示服务端行为
            }
            #endif
            _ = data
            return nil
        } catch let error as APIError {
            return error.localizedDescription
        } catch {
            return error.localizedDescription
        }
    }

    /// 真实 Sign in with Apple（可编程请求，用于协议同意后）。
    @discardableResult
    func signInWithApple() async -> String? {
        do {
            let result = try await AppleSignInService.signIn()
            return applyAppleCredential(
                userID: result.userID,
                displayName: result.email
                    ?? [result.fullName?.givenName, result.fullName?.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
            )
        } catch AppleSignInError.canceled {
            return nil
        } catch {
            return error.localizedDescription
        }
    }

    /// `SignInWithAppleButton` 回调已取得凭证时写入会话（避免二次弹窗）。
    @discardableResult
    func signInWithAppleUsingCredential(userID: String, displayName: String) async -> String? {
        applyAppleCredential(userID: userID, displayName: displayName)
    }

    @discardableResult
    private func applyAppleCredential(userID: String, displayName: String) -> String? {
        AuthTokenStore.appleUserID = userID
        let label = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        applySignedIn(
            phone: label.isEmpty ? "apple.\(userID.prefix(8))" : label,
            provider: .apple
        )
        return nil
    }

    #if DEBUG
    func signInDemoApple() {
        applySignedIn(phone: phoneNumber.isEmpty || phoneNumber == "demo.wechat" ? "demo.apple" : phoneNumber, provider: .apple)
    }

    func signInDemoWeChat() {
        applySignedIn(phone: phoneNumber.isEmpty || phoneNumber == "demo.apple" ? "demo.wechat" : phoneNumber, provider: .wechat)
    }
    #endif

    /// 以访客身份继续：不绑定手机号，保留本机 UUID。
    func continueAsGuest() {
        LocalUserIdentity.ensure()
        phoneNumber = ""
        provider = .guest
        isGuest = true
        isSignedIn = true
        AuthTokenStore.clear()
    }

    func signOut() {
        isSignedIn = false
        isGuest = false
        provider = .guest
        AuthTokenStore.clear()
    }

    func resetStoredSession() {
        phoneNumber = ""
        isGuest = false
        isSignedIn = false
        provider = .guest
        AuthTokenStore.clearAllIncludingAppleUser()
        UserDefaults.standard.removeObject(forKey: Keys.phone)
        UserDefaults.standard.removeObject(forKey: Keys.signedIn)
        UserDefaults.standard.removeObject(forKey: Keys.guest)
        UserDefaults.standard.removeObject(forKey: Keys.provider)
        LocalUserIdentity.regenerate()
    }

    /// 刷新失败等场景：清会话并回到登录。
    func invalidateRemoteSession() {
        AuthTokenStore.clear()
        if provider != .guest, !isGuest {
            isSignedIn = false
            provider = .guest
        }
    }

    private func applySignedIn(phone: String, provider: LocalAccountProvider) {
        LocalUserIdentity.ensure()
        phoneNumber = phone
        self.provider = provider
        isGuest = false
        isSignedIn = true
    }

    private static func inferredProvider(isGuest: Bool, phone: String) -> LocalAccountProvider {
        if isGuest { return .guest }
        switch phone {
        case "demo.apple": return .apple
        case "demo.wechat": return .wechat
        case "": return .guest
        default:
            if phone.hasPrefix("apple.") { return .apple }
            return .phone
        }
    }
}
