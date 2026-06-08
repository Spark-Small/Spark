// Module: SparkAuth — Authentication service boundary.

import Foundation

public struct AppleSignInCredential: Sendable, Equatable {
    public let identityToken: Data
    public let authorizationCode: Data?

    public init(identityToken: Data, authorizationCode: Data?) {
        self.identityToken = identityToken
        self.authorizationCode = authorizationCode
    }
}

/// Signs users in via Apple / CN providers and restores persisted sessions.
public protocol AuthService: Sendable {
    func restoreSession() async throws -> AuthSession?
    func signInWithApple(_ credential: AppleSignInCredential) async throws -> AuthSession
    func signInWithWeChat(_ credential: WeChatSignInCredential) async throws -> AuthSession
    func signInWithPhoneOneTap(_ credential: PhoneOneTapSignInCredential) async throws -> AuthSession
    func sendPhoneOTP(_ phone: String) async throws
    func signInWithPhoneOTP(phone: String, code: String) async throws -> AuthSession
    func fetchAlipayAuthInfo() async throws -> AlipayAuthInfo
    func signInWithAlipay(_ credential: AlipaySignInCredential) async throws -> AuthSession
    /// Staging / CI only — not used by login UI.
    func signInWithEmail(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
}
