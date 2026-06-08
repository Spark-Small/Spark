// Module: Spark App — Aliyun DYPNS / ATAuth one-tap login.
// REASONING: Link ATAuthSDK from Vendor/AliyunPhoneAuth when SPARK_HAS_ALIYUN_PHONE_SDK is set.

import Foundation
import SparkAuth

#if SPARK_HAS_ALIYUN_PHONE_SDK
import ATAuthSDK
import UIKit

@MainActor
final class AliyunPhoneOneTapCoordinator: PhoneOneTapSignInCoordinating {
    func signIn() async throws -> PhoneOneTapSignInCredential {
        guard let sdkKey = CNVendorConfiguration.aliyunPhoneSDKKey else {
            throw AuthError.providerNotConfigured(.phoneOneTap)
        }
        TXCommonHandler.sharedInstance().setAuthSDKInfo(sdkKey) { _ in }
        let token: String = try await withCheckedThrowingContinuation { continuation in
            TXCommonHandler.sharedInstance().getLoginToken(withTimeout: 3.0, controller: topViewController()) { result in
                guard let code = result["resultCode"] as? String else {
                    continuation.resume(throwing: AuthError.phoneOneTapUnavailable)
                    return
                }
                if code == "600000", let loginToken = result["token"] as? String {
                    continuation.resume(returning: loginToken)
                } else if code == "700000" {
                    continuation.resume(throwing: AuthError.userCancelled)
                } else {
                    continuation.resume(throwing: AuthError.phoneOneTapUnavailable)
                }
            }
        }
        return PhoneOneTapSignInCredential(provider: .aliyun, token: token)
    }

    private func topViewController() -> UIViewController {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController ?? UIViewController()
    }
}
#else
@MainActor
final class AliyunPhoneOneTapCoordinator: PhoneOneTapSignInCoordinating {
    func signIn() async throws -> PhoneOneTapSignInCredential {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await PreviewPhoneOneTapSignInCoordinator(provider: .aliyun).signIn()
        }
        throw AuthError.providerNotConfigured(.phoneOneTap)
    }
}
#endif
