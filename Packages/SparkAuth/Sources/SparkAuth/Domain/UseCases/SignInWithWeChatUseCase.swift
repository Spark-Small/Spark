// Module: SparkAuth — WeChat sign in.

import Foundation

public struct SignInWithWeChatUseCase: Sendable {
    private let authService: any AuthService

    public init(authService: any AuthService) {
        self.authService = authService
    }

    public func callAsFunction(_ credential: WeChatSignInCredential) async throws -> AuthSession {
        try await authService.signInWithWeChat(credential)
    }
}
