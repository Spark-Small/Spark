// Module: SparkAuthTests — MockAuthService phone OTP

import SparkAuth
import SparkPersistence
import Testing

struct MockAuthServiceOTPTests {
    private func makeService() -> MockAuthService {
        let keychain = InMemoryKeychainManager()
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
        service.simulatedDelayNanoseconds = 0
        return service
    }

    @Test func phoneOTPRequiresSendBeforeVerify() async throws {
        let service = makeService()
        do {
            _ = try await service.signInWithPhoneOTP(phone: "13800138000", code: MockAuthService.mockVerificationCode)
            Issue.record("Expected invalid verification code without prior send")
        } catch let error as AuthError {
            #expect(error == .invalidVerificationCode)
        }
    }

    @Test func phoneOTPSignInAfterSend() async throws {
        let service = makeService()
        try await service.sendPhoneOTP(phone: "13800138000")
        let session = try await service.signInWithPhoneOTP(
            phone: "13800138000",
            code: MockAuthService.mockVerificationCode
        )
        #expect(session.userID.rawValue == "phone-13800138000")
    }

    @Test func phoneOTPResendWithinCooldownFails() async throws {
        let service = makeService()
        try await service.sendPhoneOTP(phone: "13800138000")
        do {
            try await service.sendPhoneOTP(phone: "13800138000")
            Issue.record("Expected rate limit on immediate resend")
        } catch let error as AuthError {
            #expect(error == .otpRateLimited)
        }
    }
}
