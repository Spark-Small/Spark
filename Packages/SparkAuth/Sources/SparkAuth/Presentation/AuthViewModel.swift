// Module: SparkAuth — Authentication UI state.

import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
public final class AuthViewModel {
    // MARK: - Published state

    public private(set) var authState: AuthState = .idle
    public var phoneNumber: String = ""
    public var otpCode: String = ""
    public private(set) var otpSent = false
    public private(set) var otpCooldownSeconds = 0
    public private(set) var isRequestingOTP = false
    public private(set) var hasAcceptedLegalTerms = false
    public var passwordResetEmail: String = ""
    public private(set) var passwordResetSent = false
    public private(set) var isRequestingPasswordReset = false
    /// Preview / shell shortcuts — not bound by `LoginView`.
    public var email: String = ""
    public var password: String = ""

    // MARK: - Dependencies

    private let restoreSessionUseCase: any RestoreSessionUseCaseProtocol
    private let signInWithAppleUseCase: any SignInWithAppleUseCaseProtocol
    private let signInWithEmailUseCase: any SignInWithEmailUseCaseProtocol
    private let requestPhoneOTPUseCase: any RequestPhoneOTPUseCaseProtocol
    private let signInWithPhoneOTPUseCase: any SignInWithPhoneOTPUseCaseProtocol
    private let signInWithThirdPartyUseCase: any SignInWithThirdPartyUseCaseProtocol
    private let clearLocalSessionUseCase: any ClearLocalSessionUseCaseProtocol
    private let requestPasswordResetUseCase: any RequestPasswordResetUseCaseProtocol
    private let signOutUseCase: any SignOutUseCaseProtocol
    private let deleteAccountUseCase: any DeleteAccountUseCaseProtocol
    private let appleSignInCoordinator: AppleSignInCoordinator
    private let thirdPartySignInCoordinator: ThirdPartySignInCoordinator
    private var otpCooldownTask: Task<Void, Never>?

    public init(
        authService: any AuthService,
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator(),
        thirdPartySignInCoordinator: ThirdPartySignInCoordinator = ThirdPartySignInCoordinator(
            policy: .mockOAuthCode
        ),
        restoreSessionUseCase: (any RestoreSessionUseCaseProtocol)? = nil,
        signInWithAppleUseCase: (any SignInWithAppleUseCaseProtocol)? = nil,
        signInWithEmailUseCase: (any SignInWithEmailUseCaseProtocol)? = nil,
        requestPhoneOTPUseCase: (any RequestPhoneOTPUseCaseProtocol)? = nil,
        signInWithPhoneOTPUseCase: (any SignInWithPhoneOTPUseCaseProtocol)? = nil,
        signInWithThirdPartyUseCase: (any SignInWithThirdPartyUseCaseProtocol)? = nil,
        clearLocalSessionUseCase: (any ClearLocalSessionUseCaseProtocol)? = nil,
        requestPasswordResetUseCase: (any RequestPasswordResetUseCaseProtocol)? = nil,
        signOutUseCase: (any SignOutUseCaseProtocol)? = nil,
        deleteAccountUseCase: (any DeleteAccountUseCaseProtocol)? = nil
    ) {
        self.restoreSessionUseCase = restoreSessionUseCase ?? RestoreSessionUseCase(authService: authService)
        self.signInWithAppleUseCase = signInWithAppleUseCase ?? SignInWithAppleUseCase(authService: authService)
        self.signInWithEmailUseCase = signInWithEmailUseCase ?? SignInWithEmailUseCase(authService: authService)
        self.requestPhoneOTPUseCase = requestPhoneOTPUseCase ?? RequestPhoneOTPUseCase(authService: authService)
        self.signInWithPhoneOTPUseCase = signInWithPhoneOTPUseCase ?? SignInWithPhoneOTPUseCase(authService: authService)
        self.signInWithThirdPartyUseCase = signInWithThirdPartyUseCase
            ?? SignInWithThirdPartyUseCase(authService: authService)
        self.clearLocalSessionUseCase = clearLocalSessionUseCase
            ?? ClearLocalSessionUseCase(authService: authService)
        self.requestPasswordResetUseCase = requestPasswordResetUseCase
            ?? RequestPasswordResetUseCase(authService: authService)
        self.signOutUseCase = signOutUseCase ?? SignOutUseCase(authService: authService)
        self.deleteAccountUseCase = deleteAccountUseCase ?? DeleteAccountUseCase(authService: authService)
        self.appleSignInCoordinator = appleSignInCoordinator
        self.thirdPartySignInCoordinator = thirdPartySignInCoordinator
    }

    // MARK: - Session

    public var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    public var isSigningIn: Bool {
        if case .loading = authState { return true }
        return false
    }

    public func restoreSessionIfNeeded() async {
        guard case .idle = authState else { return }
        await restoreSession()
    }

    public func restoreSession() async {
        authState = .loading
        do {
            if let session = try await restoreSessionUseCase() {
                authState = .authenticated(session)
            } else {
                authState = .unauthenticated
            }
        } catch is CancellationError {
            authState = .unauthenticated
        } catch {
            setAuthFailure(from: error)
        }
    }

    public func dismissFailure() {
        if case .failure = authState {
            authState = .unauthenticated
        }
    }

    // MARK: - Phone OTP (LoginView primary)

    public var canRequestOTP: Bool {
        hasAcceptedLegalTerms
            && PhoneNumberValidator.isValidCNMobile(phoneNumber)
            && otpCooldownSeconds == 0
            && !isRequestingOTP
    }

    public var canSignInWithOTP: Bool {
        otpSent
            && PhoneNumberValidator.isValidCNMobile(phoneNumber)
            && otpCode.count >= 4
    }

    public var showsPhoneTrailingAccessory: Bool {
        isRequestingOTP || otpCooldownSeconds > 0 || canRequestOTP
    }

    public var normalizedPhoneNumber: String {
        PhoneNumberValidator.normalizedDigits(phoneNumber)
    }

    public var canUseThirdPartySignIn: Bool {
        hasAcceptedLegalTerms && !isSigningIn && !isRequestingOTP
    }

    public func setLegalTermsAccepted(_ accepted: Bool) {
        hasAcceptedLegalTerms = accepted
    }

    public func resetPhoneOTPEntry() {
        otpCode = ""
        otpSent = false
        stopOTPCooldown()
    }

    public func cancelLoginTapped() {
        guard !isSigningIn else { return }
        phoneNumber = ""
        resetPhoneOTPEntry()
        isRequestingOTP = false
        dismissFailure()
    }

    public func requestOTPTapped() async {
        guard canRequestOTP else {
            if !hasAcceptedLegalTerms {
                setAuthFailure(from: AuthError.legalConsentRequired)
            }
            return
        }
        AuthTelemetry.loginStarted(method: "phone_otp_request")
        isRequestingOTP = true
        defer { isRequestingOTP = false }
        do {
            try await requestPhoneOTPUseCase(phoneNumber: normalizedPhoneNumber)
            otpSent = true
            startOTPCooldown(seconds: 60)
        } catch is CancellationError {
            return
        } catch {
            AuthTelemetry.loginFailed(method: "phone_otp_request", reason: authFailureReason(from: error))
            setAuthFailure(from: error)
        }
    }

    public func signInWithPhoneOTPTapped() async {
        guard hasAcceptedLegalTerms else {
            setAuthFailure(from: AuthError.legalConsentRequired)
            return
        }
        guard canSignInWithOTP else { return }
        AuthTelemetry.loginStarted(method: "phone_otp")
        authState = .loading
        do {
            let session = try await signInWithPhoneOTPUseCase(
                phoneNumber: normalizedPhoneNumber,
                code: otpCode
            )
            authState = .authenticated(session)
            AuthTelemetry.loginSucceeded(method: "phone_otp")
        } catch is CancellationError {
            authState = .unauthenticated
        } catch {
            AuthTelemetry.loginFailed(method: "phone_otp", reason: authFailureReason(from: error))
            setAuthFailure(from: error)
        }
    }

    // MARK: - Password reset (ForgotPasswordView)

    public var canRequestPasswordReset: Bool {
        passwordResetEmail.contains("@")
    }

    public func requestPasswordResetTapped() async {
        isRequestingPasswordReset = true
        passwordResetSent = false
        defer { isRequestingPasswordReset = false }
        do {
            try await requestPasswordResetUseCase(email: passwordResetEmail)
            passwordResetSent = true
        } catch is CancellationError {
            return
        } catch {
            setAuthFailure(from: error)
        }
    }

    // MARK: - Alternate sign-in (preview / shell / tests)

    public func signInWithEmailTapped() async {
        authState = .loading
        do {
            let session = try await signInWithEmailUseCase(email: email, password: password)
            authState = .authenticated(session)
        } catch is CancellationError {
            authState = .unauthenticated
        } catch {
            setAuthFailure(from: error)
        }
    }

    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        authState = .loading
        switch result {
        case let .success(authorization):
            await completeAppleSignIn(authorization: authorization)
        case let .failure(error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                authState = .unauthenticated
            } else {
                setAuthFailure(from: error)
            }
        }
    }

    /// Programmatic Apple sign-in (tests / alternate entry).
    public func signInWithAppleTapped() async {
        guard hasAcceptedLegalTerms else {
            setAuthFailure(from: AuthError.legalConsentRequired)
            return
        }
        AuthTelemetry.loginStarted(method: "apple")
        authState = .loading
        do {
            let credential = try await appleSignInCoordinator.signIn()
            try await applyAppleCredential(credential)
            AuthTelemetry.loginSucceeded(method: "apple")
        } catch is CancellationError, AppleSignInCoordinatorError.cancelled {
            authState = .unauthenticated
        } catch {
            AuthTelemetry.loginFailed(method: "apple", reason: authFailureReason(from: error))
            setAuthFailure(from: error)
        }
    }

    func thirdPartySignInTapped(_ kind: LoginThirdPartySignInKind) async {
        guard hasAcceptedLegalTerms else {
            setAuthFailure(from: AuthError.legalConsentRequired)
            return
        }
        switch kind {
        case .apple:
            await signInWithAppleTapped()
        case .weChat:
            await signInWithThirdPartyTapped(.weChat)
        case .alipay:
            await signInWithThirdPartyTapped(.alipay)
        }
    }

    /// Clears local session when any authenticated API returns `401`.
    public func handleSessionInvalidated() async {
        guard isAuthenticated else { return }
        AuthTelemetry.sessionInvalidated()
        do {
            try await clearLocalSessionUseCase()
        } catch {
            // REASONING: Keychain clear is best-effort; UI must still return to login.
        }
        clearStoredCredentials()
        authState = .unauthenticated
    }

    // MARK: - Account lifecycle

    public func signOutTapped() async {
        guard case let .authenticated(previousSession) = authState else { return }
        authState = .loading
        do {
            try await signOutUseCase()
            clearStoredCredentials()
            authState = .unauthenticated
        } catch is CancellationError {
            authState = .authenticated(previousSession)
        } catch {
            setAuthFailure(from: error)
        }
    }

    public func deleteAccountTapped() async {
        guard case let .authenticated(previousSession) = authState else { return }
        authState = .loading
        do {
            try await deleteAccountUseCase()
            clearStoredCredentials()
            authState = .unauthenticated
        } catch is CancellationError {
            authState = .authenticated(previousSession)
        } catch {
            setAuthFailure(from: error)
        }
    }

#if DEBUG
    /// Previews only — simulates OTP field expansion without network.
    public func configurePreviewPhoneOTP(phoneNumber: String, otpSent: Bool) {
        self.phoneNumber = phoneNumber
        self.otpSent = otpSent
    }

    /// Previews only — OTP resend cooldown on the phone row.
    public func configurePreviewOTPCooldown(seconds: Int) {
        otpCooldownSeconds = seconds
    }

    /// Previews only — signing-in state on the login screen.
    public func configurePreviewSigningIn() {
        phoneNumber = "18812345678"
        otpCode = "123456"
        otpSent = true
        authState = .loading
    }

    /// Previews only — failure alert on the login screen.
    public func configurePreviewLoginFailure(message: String = "验证码不正确或已过期") {
        phoneNumber = "18812345678"
        otpCode = "000000"
        otpSent = true
        authState = .failure(message: message)
    }
#endif

    // MARK: - Private

    private func completeAppleSignIn(authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let token = credential.identityToken else {
            authState = .failure(message: AuthError.appleSignInFailed.errorDescription ?? "")
            return
        }
        let apple = AppleSignInCredential(identityToken: token, authorizationCode: credential.authorizationCode)
        do {
            try await applyAppleCredential(apple)
        } catch is CancellationError {
            authState = .unauthenticated
        } catch {
            setAuthFailure(from: error)
        }
    }

    private func applyAppleCredential(_ credential: AppleSignInCredential) async throws {
        let session = try await signInWithAppleUseCase(credential)
        authState = .authenticated(session)
    }

    private func signInWithThirdPartyTapped(_ provider: AuthThirdPartyLoginProvider) async {
        AuthTelemetry.loginStarted(method: provider.rawValue)
        authState = .loading
        do {
            let credential = try await thirdPartySignInCoordinator.signIn(for: provider)
            let session = try await signInWithThirdPartyUseCase(credential)
            authState = .authenticated(session)
            AuthTelemetry.loginSucceeded(method: provider.rawValue)
        } catch is CancellationError, ThirdPartySignInCoordinator.CoordinatorError.cancelled {
            authState = .unauthenticated
        } catch {
            AuthTelemetry.loginFailed(method: provider.rawValue, reason: authFailureReason(from: error))
            setAuthFailure(from: error)
        }
    }

    private func startOTPCooldown(seconds: Int) {
        stopOTPCooldown()
        otpCooldownSeconds = seconds
        otpCooldownTask = Task { [weak self] in
            guard let self else { return }
            while otpCooldownSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                otpCooldownSeconds -= 1
            }
        }
    }

    private func stopOTPCooldown() {
        otpCooldownTask?.cancel()
        otpCooldownSeconds = 0
    }

    private func clearStoredCredentials() {
        email = ""
        password = ""
        phoneNumber = ""
        resetPhoneOTPEntry()
    }

    private func setAuthFailure(from error: Error) {
        if let error = error as? AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } else {
            authState = .failure(message: error.localizedDescription)
        }
    }

    private func authFailureReason(from error: Error) -> String {
        if let error = error as? AuthError {
            return error.errorDescription ?? "auth_error"
        }
        return "unknown"
    }
}
