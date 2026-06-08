// Module: Spark App — Primary/fallback phone one-tap facade (Aliyun ↔ Tencent).

import Foundation
import SparkAuth

@MainActor
final class PhoneOneTapCoordinatorFacade: PhoneOneTapSignInCoordinating {
    private let aliyun = AliyunPhoneOneTapCoordinator()
    private let tencent = TencentPhoneOneTapCoordinator()

    func signIn() async throws -> PhoneOneTapSignInCredential {
        let primary = CNVendorConfiguration.phoneOneTapPrimary
        let secondary: PhoneOneTapProvider = primary == .aliyun ? .tencent : .aliyun
        do {
            return try await coordinator(for: primary).signIn()
        } catch let error as AuthError where error == .userCancelled {
            throw error
        } catch {
            return try await coordinator(for: secondary).signIn()
        }
    }

    private func coordinator(for provider: PhoneOneTapProvider) -> any PhoneOneTapSignInCoordinating {
        provider == .aliyun ? aliyun : tencent
    }
}
