// Module: SparkAuth — Restores persisted credentials on launch.

import Foundation

public struct RestoreSessionUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction() async throws -> AuthSession? {
        try await authService.restoreSession()
    }
}
