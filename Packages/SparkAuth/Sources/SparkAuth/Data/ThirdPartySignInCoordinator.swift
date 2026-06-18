// Module: SparkAuth — Presents WeChat / Alipay OAuth (SDK or staging simulation).

import Foundation

/// How the coordinator obtains an OAuth `code` before the backend token exchange.
public enum ThirdPartySignInSimulationPolicy: Sendable {
    /// Local mock API — deterministic codes without leaving the app.
    case mockOAuthCode
    /// Staging CloudBase API — codes accepted by `POST /v1/auth/wechat|alipay`.
    case stagingOAuthCode
    /// Production — requires WeChat Open SDK / Alipay SDK (MODULE-H).
    case requiresSDK
}

public final class ThirdPartySignInCoordinator: Sendable {
    public enum CoordinatorError: Error, Sendable {
        case cancelled
    }

    private let policy: ThirdPartySignInSimulationPolicy

    public init(policy: ThirdPartySignInSimulationPolicy = .requiresSDK) {
        self.policy = policy
    }

    /// Obtains an OAuth authorization code for the given provider.
    public func signIn(for provider: AuthThirdPartyLoginProvider) async throws -> ThirdPartyOAuthCredential {
        switch policy {
        case .mockOAuthCode:
            ThirdPartyOAuthCredential(
                provider: provider,
                authorizationCode: "mock_\(provider.rawValue)_oauth_code"
            )
        case .stagingOAuthCode:
            ThirdPartyOAuthCredential(
                provider: provider,
                authorizationCode: "staging_\(provider.rawValue)_oauth_code"
            )
        case .requiresSDK:
            // REASONING: Native SDK delegate flow lands here when MODULE-H ships.
            throw AuthError.thirdPartySDKNotConfigured(provider)
        }
    }
}
