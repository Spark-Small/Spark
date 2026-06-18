// Module: SparkAuth — ViewModel factory; keeps AuthService out of SwiftUI Views.

import Foundation

public struct AuthCoordinator: Sendable {
    private let authService: any AuthService
    private let thirdPartySignInCoordinator: ThirdPartySignInCoordinator

    public init(
        authService: any AuthService,
        thirdPartySignInCoordinator: ThirdPartySignInCoordinator = ThirdPartySignInCoordinator(
            policy: .mockOAuthCode
        )
    ) {
        self.authService = authService
        self.thirdPartySignInCoordinator = thirdPartySignInCoordinator
    }

    @MainActor
    public func makeAuthViewModel(
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator()
    ) -> AuthViewModel {
        AuthViewModel(
            authService: authService,
            appleSignInCoordinator: appleSignInCoordinator,
            thirdPartySignInCoordinator: thirdPartySignInCoordinator
        )
    }
}
