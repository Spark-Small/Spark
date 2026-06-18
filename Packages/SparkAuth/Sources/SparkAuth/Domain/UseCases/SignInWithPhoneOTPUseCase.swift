// Module: SparkAuth — Phone number + SMS OTP sign in.

import Foundation

public struct SignInWithPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(phoneNumber: String, code: String) async throws -> AuthSession {
        try await authService.signInWithPhoneOTP(phoneNumber: phoneNumber, code: code)
    }
}
