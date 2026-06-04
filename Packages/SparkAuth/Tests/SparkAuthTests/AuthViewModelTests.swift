// Module: SparkAuthTests

import SparkAuth
import SparkPersistence
import Testing

@MainActor
struct AuthViewModelTests {
    private func makeService() -> MockAuthService {
        let keychain = InMemoryKeychainManager()
        return MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
    }

    @Test func restoreWithNoSessionShowsLogin() async {
        let viewModel = AuthViewModel(authService: makeService())
        await viewModel.restoreSession()
        #expect(viewModel.authState == .unauthenticated)
    }

    @Test func emailSignInAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.email = "demo@spark.app"
        viewModel.password = "password1"
        await viewModel.signInWithEmailTapped()
        #expect(viewModel.isAuthenticated)
    }

    @Test func signOutReturnsToLogin() async {
        let service = makeService()
        let viewModel = AuthViewModel(authService: service)
        viewModel.email = "demo@spark.app"
        viewModel.password = "password1"
        await viewModel.signInWithEmailTapped()
        await viewModel.signOutTapped()
        #expect(viewModel.authState == .unauthenticated)
    }
}
