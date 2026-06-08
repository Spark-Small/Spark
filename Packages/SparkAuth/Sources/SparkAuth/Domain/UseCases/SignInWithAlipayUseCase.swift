// Module: SparkAuth — Alipay sign in.

import Foundation

public struct FetchAlipayAuthInfoUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction() async throws -> AlipayAuthInfo {
        try await authService.fetchAlipayAuthInfo()
    }
}

public struct SignInWithAlipayUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ credential: AlipaySignInCredential) async throws -> AuthSession {
        try await authService.signInWithAlipay(credential)
    }
}
