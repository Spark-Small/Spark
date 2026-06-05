// Module: SparkPersistence — Keychain-backed access token for HTTP authorization.

import Foundation
import SparkCore

public actor KeychainAccessTokenProvider: AccessTokenProviding {
    public static let defaultAccount = "access_token"

    private let keychain: any KeychainStoring
    private let account: String

    public init(keychain: any KeychainStoring = KeychainManager(), account: String = defaultAccount) {
        self.keychain = keychain
        self.account = account
    }

    public func accessToken() async -> String? {
        // REASONING: No token in Keychain is a normal unauthenticated state, not a failure to surface.
        guard let data = try? keychain.load(account: account) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    public func store(token: String) throws {
        guard let data = token.data(using: .utf8) else { return }
        try keychain.save(data, account: account)
    }

    public func clear() throws {
        try keychain.delete(account: account)
    }
}
