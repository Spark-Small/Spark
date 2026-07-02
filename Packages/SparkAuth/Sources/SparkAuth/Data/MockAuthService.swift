// Module: SparkAuth — In-memory / Keychain auth for mock API hosts and previews.

import Foundation
import SparkCore
import SparkPersistence

public final class MockAuthService: AuthService, @unchecked Sendable {
    // REASONING: Mutable mock; only used on MainActor UI and single-threaded tests.
    private struct OTPRecord: Sendable {
        let code: String
        let expiresAt: Date
        let lastSentAt: Date
    }

    /// Fixed code for Mock / Preview; Staging logs a random code to server console.
    public static let mockVerificationCode = "123456"

    private static let otpTTL: TimeInterval = 5 * 60
    private static let resendCooldown: TimeInterval = 60

    private let sessionStore: AuthSessionStore
    private let tokenProvider: KeychainAccessTokenProvider
    public var simulatedDelayNanoseconds: UInt64 = 200_000_000
    private var registeredEmails: Set<String> = []
    private var phoneOTPs: [String: OTPRecord] = [:]

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
        registeredEmails.insert(email.lowercased())
        return session
    }

    public func sendPhoneOTP(phone: String) async throws {
        try await sleepIfNeeded()
        guard PhoneNumberValidator.isValidCNMobile(phone) else {
            throw AuthError.invalidPhone
        }
        let now = Date()
        if let existing = phoneOTPs[phone],
           now.timeIntervalSince(existing.lastSentAt) < Self.resendCooldown {
            throw AuthError.otpRateLimited
        }
        phoneOTPs[phone] = OTPRecord(
            code: Self.mockVerificationCode,
            expiresAt: now.addingTimeInterval(Self.otpTTL),
            lastSentAt: now
        )
    }

    public func signInWithPhoneOTP(phone: String, code: String) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard PhoneNumberValidator.isValidCNMobile(phone) else {
            throw AuthError.invalidPhone
        }
        try verifyOTP(phone: phone, code: code)
        let digits = PhoneNumberValidator.normalizedDigits(phone)
        let session = AuthSession(userID: UserID("phone-\(digits)"), accessToken: "mock-phone-otp-token")
        try await persist(session)
        return session
    }

    public func resetPasswordWithPhoneOTP(
        phone: String,
        code: String,
        newPassword: String
    ) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard PhoneNumberValidator.isValidCNMobile(phone) else {
            throw AuthError.invalidPhone
        }
        guard newPassword.count >= 6 else {
            throw AuthError.invalidCredentials
        }
        try verifyOTP(phone: phone, code: code)
        let digits = PhoneNumberValidator.normalizedDigits(phone)
        let session = AuthSession(
            userID: UserID("phone-\(digits)"),
            accessToken: "mock-phone-reset-token"
        )
        try await persist(session)
        return session
    }

    public func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthSession {
        try await sleepIfNeeded()
        guard email.contains("@") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.invalidCredentials }
        guard !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AuthError.invalidCredentials
        }
        let normalized = email.lowercased()
        guard !registeredEmails.contains(normalized) else { throw AuthError.emailAlreadyRegistered }
        registeredEmails.insert(normalized)
        let localPart = email.split(separator: "@").first.map(String.init) ?? "user"
        let session = AuthSession(userID: UserID(localPart), accessToken: "mock-signup-token")
        try await persist(session)
        return session
    }

    @available(*, deprecated, message: "Use resetPasswordWithPhoneOTP; email reset is legacy API only.")
    public func requestPasswordReset(email: String) async throws {
        try await sleepIfNeeded()
        guard email.contains("@") else { throw AuthError.invalidEmail }
    }

    public func signOut() async throws {
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    public func deleteAccount() async throws {
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    private func verifyOTP(phone: String, code: String) throws {
        guard let record = phoneOTPs[phone] else {
            throw AuthError.invalidVerificationCode
        }
        if Date() > record.expiresAt {
            phoneOTPs.removeValue(forKey: phone)
            throw AuthError.invalidVerificationCode
        }
        guard code == record.code else {
            throw AuthError.invalidVerificationCode
        }
        phoneOTPs.removeValue(forKey: phone)
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
