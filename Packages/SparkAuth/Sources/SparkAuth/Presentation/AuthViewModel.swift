// Module: SparkAuth — Authentication UI state.

import AuthenticationServices
import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
public final class AuthViewModel {
    public private(set) var authState: AuthState = .idle
    public private(set) var activeSignInProvider: SignInProvider?
    public var loginPhone: String = ""
    public var loginVerificationCode: String = ""
    public private(set) var loginOTPSent = false
    public private(set) var isSendingLoginOTP = false
    public private(set) var loginOTPResendSecondsRemaining = 0
    public var signUpEmail: String = ""
    public var signUpPassword: String = ""
    public var signUpDisplayName: String = ""
    public var passwordResetPhone: String = ""
    public var passwordResetVerificationCode: String = ""
    public var passwordResetNewPassword: String = ""
    public private(set) var passwordResetOTPSent = false
    public private(set) var isSendingPasswordResetOTP = false
    public private(set) var passwordResetOTPResendSecondsRemaining = 0
    public private(set) var isResettingPassword = false
    public private(set) var isSigningUp = false

    private var loginOTPResendTask: Task<Void, Never>?
    private var passwordResetOTPResendTask: Task<Void, Never>?

    private let restoreSessionUseCase: any RestoreSessionUseCaseProtocol
    private let signInWithAppleUseCase: any SignInWithAppleUseCaseProtocol
    private let signInWithEmailUseCase: any SignInWithEmailUseCaseProtocol
    private let sendPhoneOTPUseCase: any SendPhoneOTPUseCaseProtocol
    private let signInWithPhoneOTPUseCase: any SignInWithPhoneOTPUseCaseProtocol
    private let resetPasswordWithPhoneOTPUseCase: any ResetPasswordWithPhoneOTPUseCaseProtocol
    private let signUpWithEmailUseCase: any SignUpWithEmailUseCaseProtocol
    private let signOutUseCase: any SignOutUseCaseProtocol
    private let deleteAccountUseCase: any DeleteAccountUseCaseProtocol
    private let appleSignInCoordinator: AppleSignInCoordinator

    // Legacy email fields — preview / tests only; login UI is phone-first.
    public var email: String = ""
    public var password: String = ""

    public init(
        authService: any AuthService,
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator(),
        restoreSessionUseCase: (any RestoreSessionUseCaseProtocol)? = nil,
        signInWithAppleUseCase: (any SignInWithAppleUseCaseProtocol)? = nil,
        signInWithEmailUseCase: (any SignInWithEmailUseCaseProtocol)? = nil,
        sendPhoneOTPUseCase: (any SendPhoneOTPUseCaseProtocol)? = nil,
        signInWithPhoneOTPUseCase: (any SignInWithPhoneOTPUseCaseProtocol)? = nil,
        resetPasswordWithPhoneOTPUseCase: (any ResetPasswordWithPhoneOTPUseCaseProtocol)? = nil,
        signUpWithEmailUseCase: (any SignUpWithEmailUseCaseProtocol)? = nil,
        signOutUseCase: (any SignOutUseCaseProtocol)? = nil,
        deleteAccountUseCase: (any DeleteAccountUseCaseProtocol)? = nil
    ) {
        self.restoreSessionUseCase = restoreSessionUseCase ?? RestoreSessionUseCase(authService: authService)
        self.signInWithAppleUseCase = signInWithAppleUseCase ?? SignInWithAppleUseCase(authService: authService)
        self.signInWithEmailUseCase = signInWithEmailUseCase ?? SignInWithEmailUseCase(authService: authService)
        self.sendPhoneOTPUseCase = sendPhoneOTPUseCase ?? SendPhoneOTPUseCase(authService: authService)
        self.signInWithPhoneOTPUseCase = signInWithPhoneOTPUseCase ?? SignInWithPhoneOTPUseCase(authService: authService)
        self.resetPasswordWithPhoneOTPUseCase = resetPasswordWithPhoneOTPUseCase
            ?? ResetPasswordWithPhoneOTPUseCase(authService: authService)
        self.signUpWithEmailUseCase = signUpWithEmailUseCase ?? SignUpWithEmailUseCase(authService: authService)
        self.signOutUseCase = signOutUseCase ?? SignOutUseCase(authService: authService)
        self.deleteAccountUseCase = deleteAccountUseCase ?? DeleteAccountUseCase(authService: authService)
        self.appleSignInCoordinator = appleSignInCoordinator
    }

    public var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    public func isLoading(for provider: SignInProvider) -> Bool {
        activeSignInProvider == provider
    }

    public var isSignInInProgress: Bool {
        activeSignInProvider != nil || isSendingLoginOTP
    }

    public var showsPhoneLoginArrow: Bool {
        isValidLoginPhone && canSendLoginOTP
    }

    public var canSendLoginOTP: Bool {
        !loginOTPSent || loginOTPResendSecondsRemaining == 0
    }

    public var canSignInWithPhoneOTP: Bool {
        loginOTPSent
            && loginVerificationCode.count == PhoneNumberValidator.verificationCodeLength
            && activeSignInProvider == nil
            && !isSendingLoginOTP
    }

    public var shouldAutoSubmitLoginOTP: Bool {
        loginOTPSent
            && loginVerificationCode.count == PhoneNumberValidator.verificationCodeLength
            && canSignInWithPhoneOTP
    }

    public var isValidLoginPhone: Bool {
        PhoneNumberValidator.isValidCNMobile(loginPhone)
    }

    public var isValidPasswordResetPhone: Bool {
        PhoneNumberValidator.isValidCNMobile(passwordResetPhone)
    }

    public var showsPasswordResetArrow: Bool {
        isValidPasswordResetPhone && canSendPasswordResetOTP
    }

    public var canSendPasswordResetOTP: Bool {
        !passwordResetOTPSent || passwordResetOTPResendSecondsRemaining == 0
    }

    public var canResetPasswordWithPhoneOTP: Bool {
        passwordResetOTPSent
            && passwordResetVerificationCode.count == PhoneNumberValidator.verificationCodeLength
            && passwordResetNewPassword.count >= 6
            && !isResettingPassword
    }

    public var canSignUp: Bool {
        signUpEmail.contains("@")
            && signUpPassword.count >= 6
            && !signUpDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var failureAlertIsPresented: Binding<Bool> {
        Binding(
            get: {
                if case .failure = self.authState { return true }
                return false
            },
            set: { isPresented in
                if !isPresented { self.dismissFailure() }
            }
        )
    }

    // MARK: - Session

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
            authState = .idle
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    // MARK: - Apple

    public func signInWithAppleTapped() async {
        await runAuthOperation(provider: .apple) {
            let credential = try await appleSignInCoordinator.signIn()
            try await applyAppleCredential(credential)
        }
    }

    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        await runAuthOperation(provider: .apple) {
            let authorization = try result.get()
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let token = credential.identityToken else {
                throw AuthError.appleSignInFailed
            }
            try await applyAppleCredential(
                AppleSignInCredential(
                    identityToken: token,
                    authorizationCode: credential.authorizationCode
                )
            )
        }
    }

    // MARK: - Phone login

    public func sendLoginPhoneOTPTapped() async {
        guard isValidLoginPhone, canSendLoginOTP else { return }
        isSendingLoginOTP = true
        defer { isSendingLoginOTP = false }
        await runAuthOperation(provider: nil) {
            let phone = PhoneNumberValidator.normalizedDigits(loginPhone)
            try await sendPhoneOTPUseCase(phone: phone)
            loginOTPSent = true
            startLoginOTPResendCooldown()
        }
    }

    public func signInWithPhoneOTPTapped() async {
        guard canSignInWithPhoneOTP else { return }
        await runAuthOperation(provider: .phoneOtp) {
            let phone = PhoneNumberValidator.normalizedDigits(loginPhone)
            let code = loginVerificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let session = try await signInWithPhoneOTPUseCase(phone: phone, code: code)
            authState = .authenticated(session)
        }
    }

    public func loginPhoneDidChange() {
        let clamped = PhoneNumberValidator.clampedCNMobileInput(loginPhone)
        if loginPhone != clamped {
            loginPhone = clamped
            return
        }
        guard loginOTPSent else { return }
        loginOTPSent = false
        loginVerificationCode = ""
        loginOTPResendTask?.cancel()
        loginOTPResendSecondsRemaining = 0
    }

    public func loginVerificationCodeDidChange() {
        let clamped = PhoneNumberValidator.clampedVerificationCode(loginVerificationCode)
        if loginVerificationCode != clamped {
            loginVerificationCode = clamped
        }
    }

    public func cancelPhoneLoginTapped() {
        clearPhoneLoginForm()
        activeSignInProvider = nil
        if case .loading = authState {
            authState = .unauthenticated
        }
    }

    // MARK: - Password reset

    public func sendPasswordResetOTPTapped() async {
        guard isValidPasswordResetPhone, canSendPasswordResetOTP else { return }
        isSendingPasswordResetOTP = true
        defer { isSendingPasswordResetOTP = false }
        await runAuthOperation(provider: nil) {
            let phone = PhoneNumberValidator.normalizedDigits(passwordResetPhone)
            try await sendPhoneOTPUseCase(phone: phone)
            passwordResetOTPSent = true
            startPasswordResetOTPResendCooldown()
        }
    }

    public func resetPasswordWithPhoneOTPTapped() async {
        guard canResetPasswordWithPhoneOTP else { return }
        isResettingPassword = true
        defer { isResettingPassword = false }
        await runAuthOperation(provider: nil) {
            let phone = PhoneNumberValidator.normalizedDigits(passwordResetPhone)
            let code = passwordResetVerificationCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let session = try await resetPasswordWithPhoneOTPUseCase(
                phone: phone,
                code: code,
                newPassword: passwordResetNewPassword
            )
            clearPasswordResetForm()
            authState = .authenticated(session)
        }
    }

    public func passwordResetPhoneDidChange() {
        let clamped = PhoneNumberValidator.clampedCNMobileInput(passwordResetPhone)
        if passwordResetPhone != clamped {
            passwordResetPhone = clamped
            return
        }
        guard passwordResetOTPSent else { return }
        passwordResetOTPSent = false
        passwordResetVerificationCode = ""
        passwordResetOTPResendTask?.cancel()
        passwordResetOTPResendSecondsRemaining = 0
    }

    public func passwordResetVerificationCodeDidChange() {
        let clamped = PhoneNumberValidator.clampedVerificationCode(passwordResetVerificationCode)
        if passwordResetVerificationCode != clamped {
            passwordResetVerificationCode = clamped
        }
    }

    public func clearPasswordResetForm() {
        passwordResetPhone = ""
        passwordResetVerificationCode = ""
        passwordResetNewPassword = ""
        passwordResetOTPSent = false
        isSendingPasswordResetOTP = false
        passwordResetOTPResendTask?.cancel()
        passwordResetOTPResendSecondsRemaining = 0
    }

    // MARK: - Email (legacy / preview)

    public func signUpWithEmailTapped() async {
        guard canSignUp else { return }
        isSigningUp = true
        defer { isSigningUp = false }
        await runAuthOperation(provider: nil) {
            let session = try await signUpWithEmailUseCase(
                email: signUpEmail,
                password: signUpPassword,
                displayName: signUpDisplayName
            )
            email = signUpEmail
            authState = .authenticated(session)
        }
    }

    public func signInWithEmailTapped() async {
        await runAuthOperation(provider: nil) {
            let session = try await signInWithEmailUseCase(email: email, password: password)
            authState = .authenticated(session)
        }
    }

    // MARK: - Sign out / delete

    public func signOutTapped() async {
        await runAuthOperation(provider: nil) {
            try await signOutUseCase()
            clearCredentialFields()
            clearPhoneLoginForm()
            authState = .unauthenticated
        }
    }

    public func deleteAccountTapped() async {
        await runAuthOperation(provider: nil) {
            try await deleteAccountUseCase()
            clearCredentialFields()
            clearPhoneLoginForm()
            authState = .unauthenticated
        }
    }

    public func dismissFailure() {
        if case .failure = authState {
            authState = .unauthenticated
        }
    }

#if DEBUG
    func prepareLoginOTPForPreview() {
        loginOTPSent = true
    }

    func preparePasswordResetOTPForPreview() {
        passwordResetOTPSent = true
    }
#endif
}

// MARK: - Private helpers

private extension AuthViewModel {
    func applyAppleCredential(_ credential: AppleSignInCredential) async throws {
        let session = try await signInWithAppleUseCase(credential)
        authState = .authenticated(session)
    }

    func runAuthOperation(provider: SignInProvider?, operation: () async throws -> Void) async {
        if let provider {
            activeSignInProvider = provider
        }
        defer {
            if provider != nil {
                activeSignInProvider = nil
            }
        }
        do {
            try await operation()
        } catch is CancellationError {
            return
        } catch AppleSignInCoordinatorError.cancelled {
            authState = .unauthenticated
        } catch let error as NSError
            where error.domain == ASAuthorizationError.errorDomain
            && error.code == ASAuthorizationError.canceled.rawValue {
            authState = .unauthenticated
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    func clearCredentialFields() {
        email = ""
        password = ""
        signUpEmail = ""
        signUpPassword = ""
        signUpDisplayName = ""
    }

    func clearPhoneLoginForm() {
        loginPhone = ""
        loginVerificationCode = ""
        loginOTPSent = false
        isSendingLoginOTP = false
        loginOTPResendTask?.cancel()
        loginOTPResendSecondsRemaining = 0
    }

    func startLoginOTPResendCooldown(seconds: Int = 60) {
        loginOTPResendTask?.cancel()
        loginOTPResendSecondsRemaining = seconds
        loginOTPResendTask = Task {
            while loginOTPResendSecondsRemaining > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                loginOTPResendSecondsRemaining -= 1
            }
        }
    }

    func startPasswordResetOTPResendCooldown(seconds: Int = 60) {
        passwordResetOTPResendTask?.cancel()
        passwordResetOTPResendSecondsRemaining = seconds
        passwordResetOTPResendTask = Task {
            while passwordResetOTPResendSecondsRemaining > 0, !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                passwordResetOTPResendSecondsRemaining -= 1
            }
        }
    }
}
