// Module: SparkAuth — Clears session and tokens.

import Foundation

public struct SignOutUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction() async throws {
        try await authService.signOut()
    }
}
