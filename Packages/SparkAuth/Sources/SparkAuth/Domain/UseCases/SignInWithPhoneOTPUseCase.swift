// Module: SparkAuth — Verify SMS OTP and sign in / register.

import Foundation

public struct SignInWithPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(phone: String, code: String) async throws -> AuthSession {
        try await authService.signInWithPhoneOTP(phone: phone, code: code)
    }
}
