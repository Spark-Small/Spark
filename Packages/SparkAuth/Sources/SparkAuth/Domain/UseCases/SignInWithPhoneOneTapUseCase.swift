// Module: SparkAuth — Phone one-tap sign in.

import Foundation

public struct SignInWithPhoneOneTapUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ credential: PhoneOneTapSignInCredential) async throws -> AuthSession {
        try await authService.signInWithPhoneOneTap(credential)
    }
}
