// Module: SparkAuth — Password reset request.

import Foundation

public struct RequestPasswordResetUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(email: String) async throws {
        try await authService.requestPasswordReset(email: email)
    }
}
