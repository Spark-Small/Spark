// Module: SparkAuth — Permanently deletes the signed-in account on server and locally.

import Foundation

public struct DeleteAccountUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction() async throws {
        try await authService.deleteAccount()
    }
}
