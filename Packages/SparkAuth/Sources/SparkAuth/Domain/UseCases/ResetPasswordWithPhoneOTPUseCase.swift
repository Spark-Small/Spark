// Module: SparkAuth — Reset password after SMS OTP verification.

import Foundation

public struct ResetPasswordWithPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    /// - Parameters:
    ///   - phone: Normalized mainland China mobile number.
    ///   - code: SMS one-time password.
    ///   - newPassword: Replacement account password.
    /// - Returns: Authenticated session after a successful reset.
    public func callAsFunction(phone: String, code: String, newPassword: String) async throws -> AuthSession {
        try await authService.resetPasswordWithPhoneOTP(phone: phone, code: code, newPassword: newPassword)
    }
}
