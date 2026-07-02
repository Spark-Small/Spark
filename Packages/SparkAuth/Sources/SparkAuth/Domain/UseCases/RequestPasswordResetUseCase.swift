// Module: SparkAuth — Legacy email password reset request (API stub only).

import Foundation

@available(*, deprecated, message: "Use ResetPasswordWithPhoneOTPUseCase; email reset is legacy API only.")
public struct RequestPasswordResetUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(email: String) async throws {
        try await authService.requestPasswordReset(email: email)
    }
}
