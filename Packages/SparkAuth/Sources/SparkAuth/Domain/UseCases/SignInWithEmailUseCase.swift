// Module: SparkAuth — Email and password sign in.

import Foundation

public struct SignInWithEmailUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(email: String, password: String) async throws -> AuthSession {
        try await authService.signInWithEmail(email: email, password: password)
    }
}
