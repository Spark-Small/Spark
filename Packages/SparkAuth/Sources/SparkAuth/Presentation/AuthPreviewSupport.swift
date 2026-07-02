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
        return AuthViewModel(authService: service)
    }

    @MainActor
    static func makeViewModelWithOTPSent() -> AuthViewModel {
        let viewModel = makeViewModel()
        viewModel.loginPhone = "13800138000"
        viewModel.prepareLoginOTPForPreview()
        return viewModel
    }

    @MainActor
    static func makeViewModelWithPasswordResetOTPSent() -> AuthViewModel {
        let viewModel = makeViewModel()
        viewModel.passwordResetPhone = "13800138000"
        viewModel.preparePasswordResetOTPForPreview()
        return viewModel
    }
}
