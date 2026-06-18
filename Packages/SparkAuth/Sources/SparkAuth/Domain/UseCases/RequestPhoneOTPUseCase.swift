// Module: SparkAuth — Request SMS one-time password.

import Foundation

public struct RequestPhoneOTPUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(phoneNumber: String) async throws {
        try await authService.requestPhoneOTP(phoneNumber: phoneNumber)
    }
}
