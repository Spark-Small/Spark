// Module: SparkAuth — In-memory / Keychain auth for mock API hosts and previews.

import Foundation
import SparkCore
import SparkPersistence

public final class MockAuthService: AuthService, @unchecked Sendable {
    // REASONING: Mutable mock; only used on MainActor UI and single-threaded tests.
    private let sessionStore: AuthSessionStore
    private let tokenProvider: KeychainAccessTokenProvider
    public var simulatedDelayNanoseconds: UInt64 = 200_000_000

    public init(sessionStore: AuthSessionStore, tokenProvider: KeychainAccessTokenProvider) {
        self.sessionStore = sessionStore
        self.tokenProvider = tokenProvider
    }

    public func restoreSession() async throws -> AuthSession? {
        try await sleepIfNeeded()
        return await sessionStore.load()
    }

    public func signInWithApple(_ credential: AppleSignInCredential) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard credential.identityToken.isEmpty == false else {
            throw AuthError.appleSignInFailed
        }
        let session = AuthSession(userID: UserID("apple-mock-user"), accessToken: "mock-apple-token")
        try await persist(session)
        return session
    }

    public func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard email.contains("@"), password.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        let localPart = email.split(separator: "@").first.map(String.init) ?? "user"
        let session = AuthSession(userID: UserID(localPart), accessToken: "mock-email-token")
        try await persist(session)
        return session
    }

    public func signOut() async throws {
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    private func persist(_ session: AuthSession) async throws {
        try await sessionStore.save(session)
        try await tokenProvider.store(token: session.accessToken)
    }

    private func sleepIfNeeded() async throws {
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }
    }
}
