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

    @Test func phoneOTPSignInAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.loginPhone = "13800138000"
        await viewModel.sendLoginPhoneOTPTapped()
        #expect(viewModel.loginOTPSent)
        viewModel.loginVerificationCode = MockAuthService.mockVerificationCode
        await viewModel.signInWithPhoneOTPTapped()
        #expect(viewModel.isAuthenticated)
    }

    @Test func phoneOTPSignInDoesNotEnterGlobalLoading() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.loginPhone = "13800138000"
        await viewModel.sendLoginPhoneOTPTapped()
        viewModel.loginVerificationCode = MockAuthService.mockVerificationCode
        await viewModel.signInWithPhoneOTPTapped()
        #expect(viewModel.isAuthenticated)
        if case .loading = viewModel.authState {
            Issue.record("Sign-in should keep the login screen visible instead of global loading")
        }
    }

    @Test func passwordResetWithPhoneOTPAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.passwordResetPhone = "13800138000"
        await viewModel.sendPasswordResetOTPTapped()
        #expect(viewModel.passwordResetOTPSent)
        viewModel.passwordResetVerificationCode = MockAuthService.mockVerificationCode
        viewModel.passwordResetNewPassword = "secret1"
        await viewModel.resetPasswordWithPhoneOTPTapped()
        #expect(viewModel.isAuthenticated)
    }

    @Test func cancelPhoneLoginResetsForm() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.loginPhone = "13800138000"
        await viewModel.sendLoginPhoneOTPTapped()
        viewModel.loginVerificationCode = MockAuthService.mockVerificationCode
        viewModel.cancelPhoneLoginTapped()
        #expect(viewModel.loginPhone.isEmpty)
        #expect(viewModel.loginVerificationCode.isEmpty)
        #expect(viewModel.loginOTPSent == false)
    }

    @Test func loginPhoneClampsToElevenDigits() {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.loginPhone = "138001380001234"
        viewModel.loginPhoneDidChange()
        #expect(viewModel.loginPhone == "13800138000")
    }

    @Test func signOutClearsPhoneLoginForm() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.loginPhone = "13800138000"
        await viewModel.sendLoginPhoneOTPTapped()
        viewModel.loginVerificationCode = MockAuthService.mockVerificationCode
        await viewModel.signInWithPhoneOTPTapped()
        await viewModel.signOutTapped()
        #expect(viewModel.loginPhone.isEmpty)
        #expect(viewModel.loginVerificationCode.isEmpty)
        #expect(viewModel.loginOTPSent == false)
    }
}
