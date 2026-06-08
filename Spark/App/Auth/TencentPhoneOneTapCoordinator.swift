// Module: Spark App — Tencent Cloud phone number authentication.
// REASONING: Link TencentCloudHuiyanSDK when SPARK_HAS_TENCENT_PHONE_SDK is set.

import Foundation
import SparkAuth

#if SPARK_HAS_TENCENT_PHONE_SDK
import UIKit

@MainActor
final class TencentPhoneOneTapCoordinator: PhoneOneTapSignInCoordinating {
    func signIn() async throws -> PhoneOneTapSignInCredential {
        guard CNVendorConfiguration.tencentPhoneAppID != nil else {
            throw AuthError.providerNotConfigured(.phoneOneTap)
        }
        // REASONING: Wrap vendor SDK; token shape matches POST /v1/auth/phone-one-tap.
        throw AuthError.phoneOneTapUnavailable
    }
}
#else
@MainActor
final class TencentPhoneOneTapCoordinator: PhoneOneTapSignInCoordinating {
    func signIn() async throws -> PhoneOneTapSignInCredential {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await PreviewPhoneOneTapSignInCoordinator(provider: .tencent).signIn()
        }
        throw AuthError.providerNotConfigured(.phoneOneTap)
    }
}
#endif
