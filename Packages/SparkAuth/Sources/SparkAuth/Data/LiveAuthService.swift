// Module: SparkAuth — Network-backed authentication.

import Foundation
import SparkCore
import SparkNetworking
import SparkPersistence

public struct LiveAuthService: AuthService, Sendable {
    private let apiClient: APIClient
    private let sessionStore: AuthSessionStore
    private let tokenProvider: KeychainAccessTokenProvider

    public init(
        apiClient: APIClient,
        sessionStore: AuthSessionStore,
        tokenProvider: KeychainAccessTokenProvider
    ) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
        self.tokenProvider = tokenProvider
    }

    public func restoreSession() async throws -> AuthSession? {
        if let cached = await sessionStore.load() {
            do {
                let dto: AuthResponseDTO = try await apiClient.get("/v1/auth/session")
                let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
                try await persist(session)
                return session
            } catch let error as AppError where error == .unauthorized {
                try await sessionStore.clear()
                try await tokenProvider.clear()
                return nil
            } catch {
                return cached
            }
        }
        return nil
    }

    public func signInWithApple(_ credential: AppleSignInCredential) async throws -> AuthSession {
        let request = AppleSignInRequestDTO(
            identityToken: credential.identityToken.base64EncodedString(),
            authorizationCode: credential.authorizationCode?.base64EncodedString()
        )
        let body = try JSONEncoder().encode(request)
        let dto: AuthResponseDTO = try await apiClient.post("/v1/auth/apple", body: body)
        let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
        try await persist(session)
        return session
    }

    public func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        let body = try JSONEncoder().encode(EmailSignInRequestDTO(email: email, password: password))
        do {
            let dto: AuthResponseDTO = try await apiClient.post("/v1/auth/email", body: body)
            let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
            try await persist(session)
            return session
        } catch let error as AppError where error == .unauthorized {
            throw AuthError.invalidCredentials
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    public func sendPhoneOTP(phone: String) async throws {
        let body = try JSONEncoder().encode(PhoneOTPRequestDTO(phone: phone))
        do {
            try await apiClient.post("/v1/auth/phone/otp", body: body)
        } catch {
            throw LiveAuthErrorMapper.mapPhoneOTP(error)
        }
    }

    public func signInWithPhoneOTP(phone: String, code: String) async throws -> AuthSession {
        let body = try JSONEncoder().encode(PhoneOTPVerifyRequestDTO(phone: phone, code: code))
        do {
            let dto: AuthResponseDTO = try await apiClient.post("/v1/auth/phone/verify", body: body)
            let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
            try await persist(session)
            return session
        } catch {
            throw LiveAuthErrorMapper.mapPhoneVerification(error)
        }
    }

    public func resetPasswordWithPhoneOTP(
        phone: String,
        code: String,
        newPassword: String
    ) async throws -> AuthSession {
        let body = try JSONEncoder().encode(
            PhonePasswordResetRequestDTO(phone: phone, code: code, newPassword: newPassword)
        )
        do {
            let dto: AuthResponseDTO = try await apiClient.post("/v1/auth/phone/password-reset", body: body)
            let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
            try await persist(session)
            return session
        } catch {
            throw LiveAuthErrorMapper.mapPhoneVerification(error)
        }
    }

    public func signUpWithEmail(email: String, password: String, displayName: String) async throws -> AuthSession {
        let body = try JSONEncoder().encode(
            EmailSignUpRequestDTO(email: email, password: password, displayName: displayName)
        )
        do {
            let dto: AuthResponseDTO = try await apiClient.post("/v1/auth/register", body: body)
            let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
            try await persist(session)
            return session
        } catch let error as AppError {
            if case .server(let code, _) = error, code == 409 {
                throw AuthError.emailAlreadyRegistered
            }
            throw AuthError.underlying(map(error))
        }
    }

    public func requestPasswordReset(email: String) async throws {
        let body = try JSONEncoder().encode(PasswordResetRequestDTO(email: email))
        do {
            try await apiClient.post("/v1/auth/password-reset", body: body)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    public func signOut() async throws {
        try await apiClient.post("/v1/auth/sign-out")
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    public func deleteAccount() async throws {
        try await apiClient.post("/v1/auth/account/delete")
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    private func persist(_ session: AuthSession) async throws {
        try await sessionStore.save(session)
        try await tokenProvider.store(token: session.accessToken)
    }

    private func map(_ error: Error) -> AppError {
        if let appError = error as? AppError { return appError }
        return .unknown(message: error.localizedDescription)
    }
}
