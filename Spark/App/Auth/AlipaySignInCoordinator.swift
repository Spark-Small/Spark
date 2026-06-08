// Module: Spark App — Alipay Open SDK authorization.
// REASONING: Link AlipaySDK when SPARK_HAS_ALIPAY_SDK is set.

import Foundation
import SparkAuth

#if SPARK_HAS_ALIPAY_SDK
import AlipaySDK

@MainActor
final class AlipaySignInCoordinator: AlipaySignInCoordinating {
    func signIn(authInfo: AlipayAuthInfo) async throws -> AlipaySignInCredential {
        guard CNVendorConfiguration.alipayAppID != nil else {
            throw AuthError.providerNotConfigured(.alipay)
        }
        let authCode: String = try await withCheckedThrowingContinuation { continuation in
            AlipaySDK.defaultService().auth_V2(withInfo: authInfo.authInfo, fromScheme: alipayURLScheme()) { result in
                guard let result,
                      let code = parseAuthCode(from: result) else {
                    continuation.resume(throwing: AuthError.invalidCredentials)
                    return
                }
                continuation.resume(returning: code)
            }
        }
        return AlipaySignInCredential(authCode: authCode)
    }

    func handleOpenURL(_ url: URL) -> Bool {
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { _, _ in }
        return url.host?.contains("safepay") == true
    }

    private func alipayURLScheme() -> String {
        "ap\(CNVendorConfiguration.alipayAppID ?? "")"
    }

    private func parseAuthCode(from result: String) -> String? {
        result
            .split(separator: "&")
            .first { $0.hasPrefix("auth_code=") }
            .map { String($0.dropFirst("auth_code=".count)) }
    }
}
#else
@MainActor
final class AlipaySignInCoordinator: AlipaySignInCoordinating {
    func signIn(authInfo: AlipayAuthInfo) async throws -> AlipaySignInCredential {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await PreviewAlipaySignInCoordinator().signIn(authInfo: authInfo)
        }
        throw AuthError.providerNotConfigured(.alipay)
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}
#endif
