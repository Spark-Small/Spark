// Module: SparkAuthTests — Auth coordinator coverage.

import SparkAuth
import SparkPersistence
import Testing

@MainActor
struct AuthCoordinatorTests {
    @Test func coordinatorBuildsAuthViewModel() {
        let service = MockAuthService(
            sessionStore: AuthSessionStore(),
            tokenProvider: KeychainAccessTokenProvider()
        )
        let coordinator = AuthCoordinator(authService: service)
        let viewModel = coordinator.makeAuthViewModel()
        #expect(viewModel.isAuthenticated == false)
    }
}
