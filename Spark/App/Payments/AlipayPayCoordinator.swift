// Module: Spark App — Alipay payment coordinator.

import Foundation
import SparkPayments

#if SPARK_HAS_ALIPAY_SDK
import AlipaySDK

@MainActor
final class AlipayPayCoordinator: AlipayPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        guard CNVendorConfiguration.alipayAppID != nil else {
            throw PaymentsError.providerNotConfigured(.alipay)
        }
        guard let orderString = order.payload.orderString else {
            throw PaymentsError.verificationFailed
        }
        let receipt: String = try await withCheckedThrowingContinuation { continuation in
            AlipaySDK.defaultService().payOrder(
                orderString,
                fromScheme: alipayURLScheme()
            ) { result in
                guard let result,
                      result["resultStatus"] as? String == "9000" else {
                    continuation.resume(throwing: PaymentsError.verificationFailed)
                    return
                }
                continuation.resume(returning: result["memo"] as? String ?? "alipay-pay-success")
            }
        }
        return CNPaymentReceipt(orderID: order.orderID, provider: .alipay, receipt: receipt)
    }

    func handleOpenURL(_ url: URL) -> Bool {
        AlipaySDK.defaultService().processOrder(withPaymentResult: url) { _, _ in }
        return url.host?.contains("safepay") == true
    }

    private func alipayURLScheme() -> String {
        "ap\(CNVendorConfiguration.alipayAppID ?? "")"
    }
}
#else
@MainActor
final class AlipayPayCoordinator: AlipayPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await StagingBridgeAlipayPayCoordinator().pay(order: order)
        }
        throw PaymentsError.providerNotConfigured(.alipay)
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}
#endif
