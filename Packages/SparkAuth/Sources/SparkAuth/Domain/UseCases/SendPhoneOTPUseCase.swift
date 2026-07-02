// Module: SparkAuth — Request SMS OTP for phone login.

import Foundation

public struct SendPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(phone: String) async throws {
        try await authService.sendPhoneOTP(phone: phone)
    }
}
