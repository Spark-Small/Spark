//
//  AuthTokenStore.swift
//  坐标系
//
//  远端 JWT 存 Keychain；供 APIClient tokenProvider / refresh 使用。
//

import CoordinateNetworking
import Foundation

enum AuthTokenStore {
    private enum Account {
        static let access = "auth.remote.accessToken"
        static let refresh = "auth.remote.refreshToken"
        static let expiresAt = "auth.remote.expiresAt"
        static let appleUserID = "auth.apple.userID"
    }

    /// 迁移期：若 Keychain 为空则读一次旧 UserDefaults 并搬走。
    private static let legacyAccessDefaultsKey = "auth.remote.accessToken"
    private static let legacyRefreshDefaultsKey = "auth.remote.refreshToken"

    static var accessToken: String? {
        get {
            migrateLegacyDefaultsIfNeeded()
            return KeychainStore.string(account: Account.access)
        }
        set { write(newValue, account: Account.access) }
    }

    static var refreshToken: String? {
        get {
            migrateLegacyDefaultsIfNeeded()
            return KeychainStore.string(account: Account.refresh)
        }
        set { write(newValue, account: Account.refresh) }
    }

    /// Access token 过期时间（Unix）。`nil` 表示未知，仍可按 401 刷新。
    static var accessTokenExpiresAt: Date? {
        get {
            guard let raw = KeychainStore.string(account: Account.expiresAt),
                  let interval = TimeInterval(raw)
            else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            if let newValue {
                write(String(newValue.timeIntervalSince1970), account: Account.expiresAt)
            } else {
                KeychainStore.remove(account: Account.expiresAt)
            }
        }
    }

    static var appleUserID: String? {
        get { KeychainStore.string(account: Account.appleUserID) }
        set { write(newValue, account: Account.appleUserID) }
    }

    static var hasTokens: Bool {
        !(accessToken ?? "").isEmpty
    }

    static var isAccessTokenExpired: Bool {
        guard let expiresAt = accessTokenExpiresAt else { return false }
        return Date() >= expiresAt.addingTimeInterval(-30)
    }

    static func save(access: String, refresh: String, expiresIn: Int? = nil) {
        accessToken = access
        refreshToken = refresh
        if let expiresIn, expiresIn > 0 {
            accessTokenExpiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            accessTokenExpiresAt = nil
        }
    }

    static func clear() {
        accessToken = nil
        refreshToken = nil
        accessTokenExpiresAt = nil
    }

    static func clearAllIncludingAppleUser() {
        clear()
        appleUserID = nil
    }

    private static func write(_ value: String?, account: String) {
        if let value, !value.isEmpty {
            try? KeychainStore.set(value, account: account)
        } else {
            KeychainStore.remove(account: account)
        }
    }

    private static func migrateLegacyDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        let legacyAccess = defaults.string(forKey: legacyAccessDefaultsKey)
        let legacyRefresh = defaults.string(forKey: legacyRefreshDefaultsKey)
        guard let legacyAccess, !legacyAccess.isEmpty else { return }
        if KeychainStore.string(account: Account.access) == nil {
            try? KeychainStore.set(legacyAccess, account: Account.access)
            if let legacyRefresh, !legacyRefresh.isEmpty {
                try? KeychainStore.set(legacyRefresh, account: Account.refresh)
            }
        }
        defaults.removeObject(forKey: legacyAccessDefaultsKey)
        defaults.removeObject(forKey: legacyRefreshDefaultsKey)
    }
}

struct StoredAPITokenProvider: APITokenProviding {
    var accessToken: String? { AuthTokenStore.accessToken }
}

/// 401 时用 refresh_token 换发 access，并写回 Keychain。
struct AuthTokenRefresher: APITokenRefreshing {
    func refreshedAccessToken() async throws -> String? {
        guard let refresh = AuthTokenStore.refreshToken, !refresh.isEmpty else {
            return nil
        }
        // 避免刷新请求再走带过期 Bearer 的 shared client 递归刷新。
        let bare = APIClient(
            baseURL: APIConfiguration.baseURL,
            tokenProvider: EmptyAPITokenProvider(),
            decoder: APIJSONCoding.makeDecoder()
        )
        do {
            let tokens = try await RemoteAuthAPI.refreshTokens(refreshToken: refresh, client: bare)
            AuthTokenStore.save(
                access: tokens.accessToken,
                refresh: tokens.refreshToken,
                expiresIn: tokens.expiresIn
            )
            return tokens.accessToken
        } catch {
            AuthTokenStore.clear()
            throw error
        }
    }
}
