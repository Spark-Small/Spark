// Module: SparkAuth — Authentication UI state.

import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
public final class AuthViewModel {
    public private(set) var authState: AuthState = .idle
    public var email: String = ""
    public var password: String = ""
    public var signUpEmail: String = ""
    public var signUpPassword: String = ""
    public var signUpDisplayName: String = ""
    public var passwordResetEmail: String = ""
    public private(set) var passwordResetSent = false
    public private(set) var isRequestingPasswordReset = false

    private let restoreSessionUseCase: any RestoreSessionUseCaseProtocol
    private let signInWithAppleUseCase: any SignInWithAppleUseCaseProtocol
    private let signInWithEmailUseCase: any SignInWithEmailUseCaseProtocol
    private let signUpWithEmailUseCase: any SignUpWithEmailUseCaseProtocol
    private let requestPasswordResetUseCase: any RequestPasswordResetUseCaseProtocol
    private let signOutUseCase: any SignOutUseCaseProtocol
    private let deleteAccountUseCase: any DeleteAccountUseCaseProtocol
    private let appleSignInCoordinator: AppleSignInCoordinator

    public init(
        authService: any AuthService,
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator(),
        restoreSessionUseCase: (any RestoreSessionUseCaseProtocol)? = nil,
        signInWithAppleUseCase: (any SignInWithAppleUseCaseProtocol)? = nil,
        signInWithEmailUseCase: (any SignInWithEmailUseCaseProtocol)? = nil,
        signUpWithEmailUseCase: (any SignUpWithEmailUseCaseProtocol)? = nil,
        requestPasswordResetUseCase: (any RequestPasswordResetUseCaseProtocol)? = nil,
        signOutUseCase: (any SignOutUseCaseProtocol)? = nil,
        deleteAccountUseCase: (any DeleteAccountUseCaseProtocol)? = nil
    ) {
        self.restoreSessionUseCase = restoreSessionUseCase ?? RestoreSessionUseCase(authService: authService)
        self.signInWithAppleUseCase = signInWithAppleUseCase ?? SignInWithAppleUseCase(authService: authService)
        self.signInWithEmailUseCase = signInWithEmailUseCase ?? SignInWithEmailUseCase(authService: authService)
        self.signUpWithEmailUseCase = signUpWithEmailUseCase ?? SignUpWithEmailUseCase(authService: authService)
        self.requestPasswordResetUseCase = requestPasswordResetUseCase
            ?? RequestPasswordResetUseCase(authService: authService)
        self.signOutUseCase = signOutUseCase ?? SignOutUseCase(authService: authService)
        self.deleteAccountUseCase = deleteAccountUseCase ?? DeleteAccountUseCase(authService: authService)
        self.appleSignInCoordinator = appleSignInCoordinator
    }

    public var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
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
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
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
                authState = .failure(message: error.localizedDescription)
            }
        }
    }

    /// Programmatic Apple sign-in (tests / alternate entry).
    public func signInWithAppleTapped() async {
        authState = .loading
        do {
            let credential = try await appleSignInCoordinator.signIn()
            try await applyAppleCredential(credential)
        } catch is CancellationError, AppleSignInCoordinatorError.cancelled {
            authState = .unauthenticated
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

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
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    private func applyAppleCredential(_ credential: AppleSignInCredential) async throws {
        let session = try await signInWithAppleUseCase(credential)
        authState = .authenticated(session)
    }

    public var canSignUp: Bool {
        signUpEmail.contains("@")
            && signUpPassword.count >= 6
            && !signUpDisplayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var canRequestPasswordReset: Bool {
        passwordResetEmail.contains("@")
    }

    public func signUpWithEmailTapped() async {
        authState = .loading
        do {
            let session = try await signUpWithEmailUseCase(
                email: signUpEmail,
                password: signUpPassword,
                displayName: signUpDisplayName
            )
            email = signUpEmail
            authState = .authenticated(session)
        } catch is CancellationError {
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
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
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    public func signInWithEmailTapped() async {
        authState = .loading
        do {
            let session = try await signInWithEmailUseCase(email: email, password: password)
            authState = .authenticated(session)
        } catch is CancellationError {
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    public func signOutTapped() async {
        authState = .loading
        do {
            try await signOutUseCase()
            email = ""
            password = ""
            authState = .unauthenticated
        } catch is CancellationError {
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    public func deleteAccountTapped() async {
        authState = .loading
        do {
            try await deleteAccountUseCase()
            email = ""
            password = ""
            authState = .unauthenticated
        } catch is CancellationError {
            return
        } catch let error as AuthError {
            authState = .failure(message: error.errorDescription ?? "")
        } catch {
            authState = .failure(message: error.localizedDescription)
        }
    }

    public func dismissFailure() {
        if case .failure = authState {
            authState = .unauthenticated
        }
    }
}
