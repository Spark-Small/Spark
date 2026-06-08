// Module: SparkAuthTests

import SparkAuth
import SparkPersistence
import Testing

@MainActor
struct AuthViewModelTests {
    private func makeViewModel() -> (AuthViewModel, MockAuthService) {
        let keychain = InMemoryKeychainManager()
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
        service.simulatedDelayNanoseconds = 0
        let viewModel = AuthViewModel(authService: service, cnCoordinators: .preview)
        return (viewModel, service)
    }

    @Test func restoreWithNoSessionShowsLogin() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.restoreSession()
        #expect(viewModel.authState == .unauthenticated)
    }

    @Test func weChatSignInAuthenticatesAndClearsProvider() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.signInWithWeChatTapped()
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.activeSignInProvider == nil)
    }

    @Test func phoneOneTapSignInAuthenticatesAndClearsProvider() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.signInWithPhoneOneTapTapped()
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.activeSignInProvider == nil)
    }

    @Test func alipaySignInAuthenticatesAndClearsProvider() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.signInWithAlipayTapped()
        #expect(viewModel.isAuthenticated)
        #expect(viewModel.activeSignInProvider == nil)
    }

    @Test func signOutReturnsToLogin() async {
        let (viewModel, _) = makeViewModel()
        await viewModel.signInWithWeChatTapped()
        await viewModel.signOutTapped()
        #expect(viewModel.authState == .unauthenticated)
    }
}
