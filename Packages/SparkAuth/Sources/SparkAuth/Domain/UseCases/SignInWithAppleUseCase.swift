// Module: SparkAuth — Apple Sign In flow.

import Foundation

public struct SignInWithAppleUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ credential: AppleSignInCredential) async throws -> AuthSession {
        try await authService.signInWithApple(credential)
    }
}
