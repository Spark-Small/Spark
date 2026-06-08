// Module: SparkAuth — Live-path placeholder when native SDK is not linked.

import Foundation

public struct UnconfiguredWeChatSignInCoordinator: WeChatSignInCoordinating {
    public init() {}

    public func registerIfNeeded() async {}

    public func signIn() async throws -> WeChatSignInCredential {
        throw AuthError.providerNotConfigured(.wechat)
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

public struct UnconfiguredPhoneOneTapSignInCoordinator: PhoneOneTapSignInCoordinating {
    public init() {}

    public func signIn() async throws -> PhoneOneTapSignInCredential {
        throw AuthError.providerNotConfigured(.phoneOneTap)
    }
}

public struct UnconfiguredAlipaySignInCoordinator: AlipaySignInCoordinating {
    public init() {}

    public func signIn(authInfo: AlipayAuthInfo) async throws -> AlipaySignInCredential {
        throw AuthError.providerNotConfigured(.alipay)
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

public extension CNAuthCoordinators {
    static var unconfigured: CNAuthCoordinators {
        CNAuthCoordinators(
            weChat: UnconfiguredWeChatSignInCoordinator(),
            phoneOneTap: UnconfiguredPhoneOneTapSignInCoordinator(),
            alipay: UnconfiguredAlipaySignInCoordinator()
        )
    }
}
