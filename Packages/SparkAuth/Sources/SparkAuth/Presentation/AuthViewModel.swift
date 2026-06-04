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

    private let restoreSessionUseCase: RestoreSessionUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let signInWithEmailUseCase: SignInWithEmailUseCase
    private let signOutUseCase: SignOutUseCase
    private let appleSignInCoordinator: AppleSignInCoordinator

    public init(
        authService: any AuthService,
        appleSignInCoordinator: AppleSignInCoordinator = AppleSignInCoordinator()
    ) {
        restoreSessionUseCase = RestoreSessionUseCase(authService: authService)
        signInWithAppleUseCase = SignInWithAppleUseCase(authService: authService)
        signInWithEmailUseCase = SignInWithEmailUseCase(authService: authService)
        signOutUseCase = SignOutUseCase(authService: authService)
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

    public func dismissFailure() {
        if case .failure = authState {
            authState = .unauthenticated
        }
    }
}
