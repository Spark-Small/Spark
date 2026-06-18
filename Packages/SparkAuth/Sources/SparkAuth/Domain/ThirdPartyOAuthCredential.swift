// Module: SparkAuth — OAuth authorization code from a third-party app.

import Foundation

public struct ThirdPartyOAuthCredential: Sendable, Equatable {
    public let provider: AuthThirdPartyLoginProvider
    public let authorizationCode: String

    public init(provider: AuthThirdPartyLoginProvider, authorizationCode: String) {
        self.provider = provider
        self.authorizationCode = authorizationCode
    }
}
