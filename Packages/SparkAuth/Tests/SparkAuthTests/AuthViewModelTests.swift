// Module: SparkAuthTests

@testable import SparkAuth
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

    @Test func phoneOTPSignInAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.setLegalTermsAccepted(true)
        viewModel.phoneNumber = "18812345678"
        await viewModel.requestOTPTapped()
        viewModel.otpCode = "123456"
        await viewModel.signInWithPhoneOTPTapped()
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

    @Test func passwordResetMarksSentForValidEmail() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.passwordResetEmail = "reset@spark.app"
        await viewModel.requestPasswordResetTapped()
        #expect(viewModel.passwordResetSent)
    }

    @Test func cancelLoginTappedClearsEntryAndFailure() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.phoneNumber = "18812345678"
        await viewModel.requestOTPTapped()
        viewModel.otpCode = "000000"
        await viewModel.signInWithPhoneOTPTapped()
        if case .failure = viewModel.authState {
            // expected
        } else {
            Issue.record("Expected failure before cancel")
        }
        viewModel.cancelLoginTapped()
        #expect(viewModel.phoneNumber.isEmpty)
        #expect(viewModel.otpCode.isEmpty)
        #expect(!viewModel.otpSent)
        #expect(viewModel.authState == .unauthenticated)
    }

    @Test func canSignInWithOTPRequiresOTPSent() {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.phoneNumber = "18812345678"
        viewModel.otpCode = "123456"
        #expect(!viewModel.canSignInWithOTP)
    }

    @Test func signInWithoutOTPSentDoesNotEnterLoading() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.setLegalTermsAccepted(true)
        viewModel.phoneNumber = "18812345678"
        viewModel.otpCode = "123456"
        await viewModel.signInWithPhoneOTPTapped()
        #expect(viewModel.authState == .idle)
        #expect(!viewModel.isSigningIn)
    }

    @Test func thirdPartyWeChatAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.setLegalTermsAccepted(true)
        await viewModel.thirdPartySignInTapped(.weChat)
        #expect(viewModel.isAuthenticated)
    }

    @Test func thirdPartyAlipayAuthenticates() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.setLegalTermsAccepted(true)
        await viewModel.thirdPartySignInTapped(.alipay)
        #expect(viewModel.isAuthenticated)
    }

    @Test func thirdPartyRequiresSDKShowsConfigurationError() async {
        let coordinator = ThirdPartySignInCoordinator(policy: .requiresSDK)
        let viewModel = AuthViewModel(
            authService: makeService(),
            thirdPartySignInCoordinator: coordinator
        )
        viewModel.setLegalTermsAccepted(true)
        await viewModel.thirdPartySignInTapped(.weChat)
        if case let .failure(message) = viewModel.authState {
            #expect(message.contains("微信") || message.contains("WeChat"))
        } else {
            Issue.record("Expected SDK not configured failure")
        }
    }

    @Test func loginRequiresLegalConsentForOTP() async {
        let viewModel = AuthViewModel(authService: makeService())
        viewModel.phoneNumber = "18812345678"
        await viewModel.requestOTPTapped()
        #expect(!viewModel.otpSent)
        if case let .failure(message) = viewModel.authState {
            #expect(message.contains("协议") || message.localizedCaseInsensitiveContains("privacy"))
        } else {
            Issue.record("Expected legal consent failure")
        }
    }

    @Test func handleSessionInvalidatedClearsAuthenticatedState() async {
        let service = makeService()
        let viewModel = AuthViewModel(authService: service)
        viewModel.setLegalTermsAccepted(true)
        viewModel.email = "demo@spark.app"
        viewModel.password = "password1"
        await viewModel.signInWithEmailTapped()
        #expect(viewModel.isAuthenticated)
        await viewModel.handleSessionInvalidated()
        #expect(viewModel.authState == .unauthenticated)
        let restored = try? await RestoreSessionUseCase(authService: service)()
        #expect(restored == nil)
    }
}
