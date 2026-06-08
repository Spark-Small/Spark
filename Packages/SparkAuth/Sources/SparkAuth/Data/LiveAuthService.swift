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

    public func signInWithWeChat(_ credential: WeChatSignInCredential) async throws -> AuthSession {
        let body = try JSONEncoder().encode(WeChatSignInRequestDTO(code: credential.code))
        return try await postAuthSession(path: "/v1/auth/wechat", body: body)
    }

    public func signInWithPhoneOneTap(_ credential: PhoneOneTapSignInCredential) async throws -> AuthSession {
        let body = try JSONEncoder().encode(
            PhoneOneTapSignInRequestDTO(provider: credential.provider.rawValue, token: credential.token)
        )
        return try await postAuthSession(path: "/v1/auth/phone-one-tap", body: body)
    }

    public func sendPhoneOTP(_ phone: String) async throws {
        let body = try JSONEncoder().encode(PhoneOtpSendRequestDTO(phone: phone))
        do {
            let _: PhoneOtpSendResponseDTO = try await apiClient.post("/v1/auth/phone-otp/send", body: body)
            return
        } catch let error as AppError {
            if case let .server(statusCode, _) = error, statusCode == 503 {
                throw AuthError.providerNotConfigured(.phoneOtp)
            }
            throw AuthError.underlying(map(error))
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    public func signInWithPhoneOTP(phone: String, code: String) async throws -> AuthSession {
        let body = try JSONEncoder().encode(PhoneOtpVerifyRequestDTO(phone: phone, code: code))
        return try await postAuthSession(path: "/v1/auth/phone-otp/verify", body: body)
    }

    public func fetchAlipayAuthInfo() async throws -> AlipayAuthInfo {
        do {
            let dto: AlipayPrepareResponseDTO = try await apiClient.get("/v1/auth/alipay/prepare")
            return AlipayAuthInfo(authInfo: dto.authInfo)
        } catch let error as AppError {
            if case let .server(statusCode, _) = error, statusCode == 503 {
                throw AuthError.providerNotConfigured(.alipay)
            }
            throw AuthError.underlying(error)
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    public func signInWithAlipay(_ credential: AlipaySignInCredential) async throws -> AuthSession {
        let body = try JSONEncoder().encode(AlipaySignInRequestDTO(authCode: credential.authCode))
        return try await postAuthSession(path: "/v1/auth/alipay", body: body)
    }

    public func signInWithEmail(email: String, password: String) async throws -> AuthSession {
        let body = try JSONEncoder().encode(EmailSignInRequestDTO(email: email, password: password))
        do {
            return try await postAuthSession(path: "/v1/auth/email", body: body)
        } catch let error as AuthError where error == .invalidCredentials {
            throw error
        } catch let error as AppError where error == .unauthorized {
            throw AuthError.invalidCredentials
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    public func signOut() async throws {
        try await apiClient.post("/v1/auth/sign-out")
        try await sessionStore.clear()
        try await tokenProvider.clear()
    }

    private func postAuthSession(path: String, body: Data) async throws -> AuthSession {
        do {
            let dto: AuthResponseDTO = try await apiClient.post(path, body: body)
            let session = AuthSession(userID: UserID(dto.userId), accessToken: dto.accessToken)
            try await persist(session)
            return session
        } catch let error as AppError {
            if case let .server(statusCode, _) = error, statusCode == 503 {
                throw mapProviderNotConfigured(path: path)
            }
            if error == .unauthorized {
                throw AuthError.invalidCredentials
            }
            throw AuthError.underlying(error)
        } catch let error as AuthError {
            throw error
        } catch {
            throw AuthError.underlying(map(error))
        }
    }

    private func mapProviderNotConfigured(path: String) -> AuthError {
        if path.contains("wechat") { return .providerNotConfigured(.wechat) }
        if path.contains("phone-otp") { return .providerNotConfigured(.phoneOtp) }
        if path.contains("phone") { return .providerNotConfigured(.phoneOneTap) }
        return .providerNotConfigured(.alipay)
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
