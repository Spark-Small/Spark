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

    public func signInWithWeChat(_ credential: WeChatSignInCredential) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard credential.code.isEmpty == false else {
            throw AuthError.invalidCredentials
        }
        let session = AuthSession(userID: UserID("wechat-mock-user"), accessToken: "mock-wechat-token")
        try await persist(session)
        return session
    }

    public func signInWithPhoneOneTap(_ credential: PhoneOneTapSignInCredential) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard credential.token.isEmpty == false else {
            throw AuthError.phoneOneTapUnavailable
        }
        let suffix = credential.provider == .aliyun ? "aliyun" : "tencent"
        let session = AuthSession(
            userID: UserID("phone-\(suffix)-mock-user"),
            accessToken: "mock-phone-\(suffix)-token"
        )
        try await persist(session)
        return session
    }

    public func sendPhoneOTP(_ phone: String) async throws {
        try await sleepIfNeeded()
        guard phone.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 else {
            throw AuthError.invalidCredentials
        }
    }

    public func signInWithPhoneOTP(phone: String, code: String) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard phone.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 else {
            throw AuthError.invalidCredentials
        }
        guard code == "123456" else {
            throw AuthError.invalidCredentials
        }
        let session = AuthSession(userID: UserID("phone-otp-mock-user"), accessToken: "mock-phone-otp-token")
        try await persist(session)
        return session
    }

    public func fetchAlipayAuthInfo() async throws -> AlipayAuthInfo {
        try await sleepIfNeeded()
        return AlipayAuthInfo(authInfo: "mock-alipay-auth-info")
    }

    public func signInWithAlipay(_ credential: AlipaySignInCredential) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard credential.authCode.isEmpty == false else {
            throw AuthError.invalidCredentials
        }
        let session = AuthSession(userID: UserID("alipay-mock-user"), accessToken: "mock-alipay-token")
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
