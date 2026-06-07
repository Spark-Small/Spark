// Module: SparkAuth — ViewModel factory; keeps AuthService out of SwiftUI Views.

import Foundation

public struct AuthCoordinator: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    @MainActor
    public func makeAuthViewModel(
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator()
    ) -> AuthViewModel {
        AuthViewModel(
            authService: authService,
            appleSignInCoordinator: appleSignInCoordinator
        )
    }
}
