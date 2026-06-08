// Module: Spark App — WeChat Open SDK coordinator.
// REASONING: Vendor XCFramework lives under Vendor/WechatOpenSDK (gitignored). Link + SPARK_HAS_WECHAT_SDK to enable.

import Foundation
import SparkAuth

#if SPARK_HAS_WECHAT_SDK
import WechatOpenSDK

@MainActor
final class WeChatSignInCoordinator: NSObject, WeChatSignInCoordinating, WXApiDelegate {
    private var continuation: CheckedContinuation<WeChatSignInCredential, Error>?

    func registerIfNeeded() async {
        guard let appID = CNVendorConfiguration.weChatAppID else { return }
        let link = CNVendorConfiguration.weChatUniversalLink ?? ""
        WXApi.registerApp(appID, universalLink: link)
    }

    func signIn() async throws -> WeChatSignInCredential {
        guard CNVendorConfiguration.weChatAppID != nil else {
            throw AuthError.providerNotConfigured(.wechat)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let request = SendAuthReq()
            request.scope = "snsapi_userinfo"
            request.state = "spark_wechat_auth"
            WXApi.send(request) { success in
                if !success {
                    continuation.resume(throwing: AuthError.weChatSignInUnavailable)
                    self.continuation = nil
                }
            }
        }
    }

    func handleOpenURL(_ url: URL) -> Bool {
        WXApi.handleOpen(url, delegate: self)
    }

    func onResp(_ resp: BaseResp) {
        guard let authResp = resp as? SendAuthResp else { return }
        if authResp.errCode == WXSuccess.rawValue, let code = authResp.code, !code.isEmpty {
            continuation?.resume(returning: WeChatSignInCredential(code: code))
        } else if authResp.errCode == WXErrCodeUserCancel.rawValue {
            continuation?.resume(throwing: AuthError.userCancelled)
        } else {
            continuation?.resume(throwing: AuthError.invalidCredentials)
        }
        continuation = nil
    }
}
#else
@MainActor
final class WeChatSignInCoordinator: WeChatSignInCoordinating {
    func registerIfNeeded() async {}

    func signIn() async throws -> WeChatSignInCredential {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await PreviewWeChatSignInCoordinator().signIn()
        }
        throw AuthError.providerNotConfigured(.wechat)
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}
#endif
