// Module: SparkAuth — Clears Keychain session without a network sign-out call.

import Foundation

public struct ClearLocalSessionUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction() async throws {
        try await authService.clearLocalSession()
    }
}
