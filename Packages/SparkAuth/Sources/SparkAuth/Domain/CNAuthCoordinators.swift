// Module: SparkAuth — CN sign-in coordinator protocols (implemented in App target).

import Foundation

public enum AuthProvider: String, Sendable, Equatable {
    case wechat
    case phoneOneTap
    case phoneOtp
    case alipay
    case apple
}

/// Presents WeChat OAuth and returns an authorization code for backend exchange.
@MainActor
public protocol WeChatSignInCoordinating {
    func registerIfNeeded() async
    func signIn() async throws -> WeChatSignInCredential
    func handleOpenURL(_ url: URL) -> Bool
}

/// Carrier one-tap login via Aliyun and/or Tencent SDKs.
@MainActor
public protocol PhoneOneTapSignInCoordinating {
    func signIn() async throws -> PhoneOneTapSignInCredential
}

/// Fetches Alipay auth_info and presents the Alipay authorization sheet.
@MainActor
public protocol AlipaySignInCoordinating {
    func signIn(authInfo: AlipayAuthInfo) async throws -> AlipaySignInCredential
    func handleOpenURL(_ url: URL) -> Bool
}

@MainActor
public struct CNAuthCoordinators {
    public let weChat: any WeChatSignInCoordinating
    public let phoneOneTap: any PhoneOneTapSignInCoordinating
    public let alipay: any AlipaySignInCoordinating

    public init(
        weChat: any WeChatSignInCoordinating,
        phoneOneTap: any PhoneOneTapSignInCoordinating,
        alipay: any AlipaySignInCoordinating
    ) {
        self.weChat = weChat
        self.phoneOneTap = phoneOneTap
        self.alipay = alipay
    }
}
