// Module: Spark App — WeChat Pay coordinator.
// REASONING: Uses WeChatOpenSDK PayReq when SPARK_HAS_WECHAT_SDK is linked.

import Foundation
import SparkPayments

#if SPARK_HAS_WECHAT_SDK
import WechatOpenSDK

@MainActor
final class WeChatPayCoordinator: NSObject, WeChatPayCoordinating, WXApiDelegate {
    private var continuation: CheckedContinuation<CNPaymentReceipt, Error>?
    private var pendingOrder: CNPaymentOrder?

    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        guard CNVendorConfiguration.weChatAppID != nil else {
            throw PaymentsError.providerNotConfigured(.wechat)
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            self.pendingOrder = order
            let request = PayReq()
            request.partnerId = order.payload.partnerID ?? ""
            request.prepayId = order.payload.prepayID ?? ""
            request.package = order.payload.packageValue ?? "Sign=WXPay"
            request.nonceStr = order.payload.nonceStr ?? ""
            request.timeStamp = UInt32(order.payload.timestamp ?? "0") ?? 0
            request.sign = order.payload.sign ?? ""
            WXApi.send(request) { success in
                if !success {
                    continuation.resume(throwing: PaymentsError.cnPaymentUnavailable)
                    self.continuation = nil
                    self.pendingOrder = nil
                }
            }
        }
    }

    func handleOpenURL(_ url: URL) -> Bool {
        WXApi.handleOpen(url, delegate: self)
    }

    func onResp(_ resp: BaseResp) {
        guard let payResp = resp as? PayResp, let order = pendingOrder else { return }
        if payResp.errCode == WXSuccess.rawValue {
            continuation?.resume(
                returning: CNPaymentReceipt(
                    orderID: order.orderID,
                    provider: .wechat,
                    receipt: payResp.returnKey ?? "wechat-pay-success"
                )
            )
        } else if payResp.errCode == WXErrCodeUserCancel.rawValue {
            continuation?.resume(throwing: PaymentsError.userCancelled)
        } else {
            continuation?.resume(throwing: PaymentsError.verificationFailed)
        }
        continuation = nil
        pendingOrder = nil
    }
}
#else
@MainActor
final class WeChatPayCoordinator: WeChatPayCoordinating {
    func pay(order: CNPaymentOrder) async throws -> CNPaymentReceipt {
        if CNVendorConfiguration.allowsStagingBridge {
            return try await StagingBridgeWeChatPayCoordinator().pay(order: order)
        }
        throw PaymentsError.providerNotConfigured(.wechat)
    }

    func handleOpenURL(_ url: URL) -> Bool { false }
}
#endif
