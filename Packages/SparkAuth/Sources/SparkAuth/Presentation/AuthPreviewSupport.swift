// Module: SparkAuth — Preview fixtures for LoginView and auth flows.

import SparkPersistence

enum AuthPreviewSupport {
    @MainActor
    static func makeViewModel() -> AuthViewModel {
        let keychain = InMemoryKeychainManager()
        let service = MockAuthService(
            sessionStore: AuthSessionStore(keychain: keychain),
            tokenProvider: KeychainAccessTokenProvider(keychain: keychain)
        )
        service.simulatedDelayNanoseconds = 0
        return AuthViewModel(authService: service, cnCoordinators: .preview)
    }
}
