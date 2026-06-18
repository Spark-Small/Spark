// Module: SparkAuth — WeChat / Alipay OAuth code exchange.

import Foundation

public struct SignInWithThirdPartyUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ credential: ThirdPartyOAuthCredential) async throws -> AuthSession {
        try await authService.signInWithThirdParty(credential)
    }
}
