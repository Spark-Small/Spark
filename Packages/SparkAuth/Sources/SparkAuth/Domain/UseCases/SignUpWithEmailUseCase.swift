// Module: SparkAuth — Email registration.

import Foundation

public struct SignUpWithEmailUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(email: String, password: String, displayName: String) async throws -> AuthSession {
        try await authService.signUpWithEmail(email: email, password: password, displayName: displayName)
    }
}
