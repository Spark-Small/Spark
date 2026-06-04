// Module: SparkAuth — Persists session fields in Keychain.

import Foundation
import SparkCore
import SparkPersistence

public actor AuthSessionStore {
    public static let tokenAccount = KeychainAccessTokenProvider.defaultAccount
    public static let userIDAccount = "user_id"

    private let keychain: any KeychainStoring

    public init(keychain: any KeychainStoring = KeychainManager()) {
        self.keychain = keychain
    }

    public func save(_ session: AuthSession) throws {
        guard let tokenData = session.accessToken.data(using: .utf8),
              let userData = session.userID.rawValue.data(using: .utf8) else {
            return
        }
        try keychain.save(tokenData, account: Self.tokenAccount)
        try keychain.save(userData, account: Self.userIDAccount)
    }

    public func load() -> AuthSession? {
        guard let tokenData = try? keychain.load(account: Self.tokenAccount),
              let userData = try? keychain.load(account: Self.userIDAccount),
              let token = String(data: tokenData, encoding: .utf8),
              let userRaw = String(data: userData, encoding: .utf8) else {
            return nil
        }
        return AuthSession(userID: UserID(userRaw), accessToken: token)
    }

    public func clear() throws {
        try keychain.delete(account: Self.tokenAccount)
        try keychain.delete(account: Self.userIDAccount)
    }
}
