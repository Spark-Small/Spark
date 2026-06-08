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

    private let restoreSessionUseCase: RestoreSessionUseCase
    private let signInWithAppleUseCase: SignInWithAppleUseCase
    private let signInWithWeChatUseCase: SignInWithWeChatUseCase
    private let signInWithPhoneOneTapUseCase: SignInWithPhoneOneTapUseCase
    private let sendPhoneOTPUseCase: SendPhoneOTPUseCase
    private let signInWithPhoneOTPUseCase: SignInWithPhoneOTPUseCase
    private let fetchAlipayAuthInfoUseCase: FetchAlipayAuthInfoUseCase
    private let signInWithAlipayUseCase: SignInWithAlipayUseCase
    private let signOutUseCase: SignOutUseCase
    private let cnCoordinators: CNAuthCoordinators

    public init(
        authService: any AuthService,
        cnCoordinators: CNAuthCoordinators = .preview
    ) {
        restoreSessionUseCase = RestoreSessionUseCase(authService: authService)
        signInWithAppleUseCase = SignInWithAppleUseCase(authService: authService)
        signInWithWeChatUseCase = SignInWithWeChatUseCase(authService: authService)
        signInWithPhoneOneTapUseCase = SignInWithPhoneOneTapUseCase(authService: authService)
        sendPhoneOTPUseCase = SendPhoneOTPUseCase(authService: authService)
        signInWithPhoneOTPUseCase = SignInWithPhoneOTPUseCase(authService: authService)
        fetchAlipayAuthInfoUseCase = FetchAlipayAuthInfoUseCase(authService: authService)
        signInWithAlipayUseCase = SignInWithAlipayUseCase(authService: authService)
        signOutUseCase = SignOutUseCase(authService: authService)
        self.cnCoordinators = cnCoordinators
    }

    public var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    /// True when the given provider is the one currently signing in (LoginView spinner).
    public func isLoading(for provider: SignInProvider) -> Bool {
        activeSignInProvider == provider
    }

    public var isSignInInProgress: Bool {
        if case .loading = authState { return true }
        return false
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
        } catch {
            resolveSignInFailure(error)
        }
    }

    public func signInWithWeChatTapped() async {
        await performSignIn(provider: .wechat) {
            await cnCoordinators.weChat.registerIfNeeded()
            let credential = try await cnCoordinators.weChat.signIn()
            return try await signInWithWeChatUseCase(credential)
        }
    }

    public func signInWithPhoneOneTapTapped() async {
        await performSignIn(provider: .phoneOneTap) {
            let credential = try await cnCoordinators.phoneOneTap.signIn()
            return try await signInWithPhoneOneTapUseCase(credential)
        }
    }

    public func sendPhoneOTP(_ phone: String) async throws {
        try await sendPhoneOTPUseCase(phone)
    }

    public func signInWithPhoneOTP(phone: String, code: String) async {
        await performSignIn(provider: .phoneOtp) {
            try await signInWithPhoneOTPUseCase(phone: phone, code: code)
        }
    }

    public func signInWithAlipayTapped() async {
        await performSignIn(provider: .alipay) {
            let authInfo = try await fetchAlipayAuthInfoUseCase()
            let credential = try await cnCoordinators.alipay.signIn(authInfo: authInfo)
            return try await signInWithAlipayUseCase(credential)
        }
    }

    public func handleAppleSignInResult(_ result: Result<ASAuthorization, Error>) async {
        authState = .loading
        activeSignInProvider = .apple
        defer { activeSignInProvider = nil }
        switch result {
        case let .success(authorization):
            await completeAppleSignIn(authorization: authorization)
        case let .failure(error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                authState = .unauthenticated
            } else {
                resolveSignInFailure(error)
            }
        }
    }

    public func signOutTapped() async {
        authState = .loading
        do {
            try await signOutUseCase()
            authState = .unauthenticated
        } catch is CancellationError {
            return
        } catch {
            resolveSignInFailure(error)
        }
    }

    public func dismissFailure() {
        if case .failure = authState {
            authState = .unauthenticated
        }
    }

    public func handleOpenURL(_ url: URL) -> Bool {
        cnCoordinators.weChat.handleOpenURL(url) || cnCoordinators.alipay.handleOpenURL(url)
    }

    private func performSignIn(provider: SignInProvider, operation: () async throws -> AuthSession) async {
        authState = .loading
        activeSignInProvider = provider
        defer { activeSignInProvider = nil }
        do {
            let session = try await operation()
            authState = .authenticated(session)
        } catch {
            resolveSignInFailure(error)
        }
    }

    private func resolveSignInFailure(_ error: Error) {
        if error is CancellationError {
            authState = .unauthenticated
            return
        }
        if let authError = error as? AuthError {
            if authError == .userCancelled {
                authState = .unauthenticated
                return
            }
            authState = .failure(message: authError.errorDescription ?? "")
            return
        }
        authState = .failure(message: error.localizedDescription)
    }

    private func completeAppleSignIn(authorization: ASAuthorization) async {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let token = credential.identityToken else {
            authState = .failure(message: AuthError.appleSignInFailed.errorDescription ?? "")
            return
        }
        let apple = AppleSignInCredential(identityToken: token, authorizationCode: credential.authorizationCode)
        do {
            let session = try await signInWithAppleUseCase(apple)
            authState = .authenticated(session)
        } catch {
            resolveSignInFailure(error)
        }
    }
}
