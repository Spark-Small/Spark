// Module: SparkAuth — Preview / unit-test CN auth coordinators.

import Foundation

@MainActor
public struct PreviewWeChatSignInCoordinator: WeChatSignInCoordinating {
    public init() {}

    public func registerIfNeeded() async {}

    public func signIn() async throws -> WeChatSignInCredential {
        WeChatSignInCredential(code: "staging-wechat-code")
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

@MainActor
public struct PreviewPhoneOneTapSignInCoordinator: PhoneOneTapSignInCoordinating {
    public let provider: PhoneOneTapProvider

    public init(provider: PhoneOneTapProvider = .aliyun) {
        self.provider = provider
    }

    public func signIn() async throws -> PhoneOneTapSignInCredential {
        let token = provider == .aliyun ? "staging-aliyun-token" : "staging-tencent-token"
        return PhoneOneTapSignInCredential(provider: provider, token: token)
    }
}

@MainActor
public struct PreviewAlipaySignInCoordinator: AlipaySignInCoordinating {
    public init() {}

    public func signIn(authInfo: AlipayAuthInfo) async throws -> AlipaySignInCredential {
        AlipaySignInCredential(authCode: "staging-alipay-code")
    }

    public func handleOpenURL(_ url: URL) -> Bool { false }
}

public extension CNAuthCoordinators {
    static var preview: CNAuthCoordinators {
        stagingBridge(phoneProvider: .aliyun)
    }

    /// Staging magic tokens (docs/STAGING.md) — used by App target when SDK binaries are absent.
    static func stagingBridge(phoneProvider: PhoneOneTapProvider) -> CNAuthCoordinators {
        CNAuthCoordinators(
            weChat: PreviewWeChatSignInCoordinator(),
            phoneOneTap: PreviewPhoneOneTapSignInCoordinator(provider: phoneProvider),
            alipay: PreviewAlipaySignInCoordinator()
        )
    }
}
