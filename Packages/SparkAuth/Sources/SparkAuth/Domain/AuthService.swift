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

/// Signs users in via Apple / email and restores persisted sessions.
public protocol AuthService: Sendable {
    func restoreSession() async throws -> AuthSession?
    func signInWithApple(_ credential: AppleSignInCredential) async throws -> AuthSession
    func signInWithEmail(email: String, password: String) async throws -> AuthSession
    func signOut() async throws
}
