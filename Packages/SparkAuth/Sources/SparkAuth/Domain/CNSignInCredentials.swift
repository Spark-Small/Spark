// Module: SparkAuth — Third-party sign-in credentials (CN providers).

import Foundation

public struct WeChatSignInCredential: Sendable, Equatable {
    public let code: String

    public init(code: String) {
        self.code = code
    }
}

public enum PhoneOneTapProvider: String, Sendable, Equatable, Codable {
    case aliyun
    case tencent
}

public struct PhoneOneTapSignInCredential: Sendable, Equatable {
    public let provider: PhoneOneTapProvider
    public let token: String

    public init(provider: PhoneOneTapProvider, token: String) {
        self.provider = provider
        self.token = token
    }
}

public struct AlipaySignInCredential: Sendable, Equatable {
    public let authCode: String

    public init(authCode: String) {
        self.authCode = authCode
    }
}

public struct AlipayAuthInfo: Sendable, Equatable {
    public let authInfo: String

    public init(authInfo: String) {
        self.authInfo = authInfo
    }
}
