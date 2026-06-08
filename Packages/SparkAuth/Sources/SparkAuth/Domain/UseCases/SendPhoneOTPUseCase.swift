// Module: SparkAuth — Send SMS OTP to a phone number.

import Foundation

public struct SendPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ phone: String) async throws {
        try await authService.sendPhoneOTP(phone)
    }
}
