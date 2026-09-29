//
//  CommercePaymentPolicy.swift
//  坐标系
//
//  支付 / 退款演示边界（Apple 审核 3.1.1 / 2.3.1：不得伪造 Apple Pay 等到账）。
//

import Foundation

enum CommercePaymentPolicy {
    /// DEBUG 允许本地模拟外部支付（Apple Pay / 微信 / 支付宝）到账。
    /// Release 仅允许真实已接入通道；当前外部通道未接，故不可选。
    static var allowsSimulatedExternalCheckout: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// Release 退款不自动 sleep 完结，保持「已提交 / 处理中」等服务端确认。
    static var simulatesLocalRefundCompletion: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// 结账页可选支付方式。
    static var checkoutMethods: [PaymentMethod] {
        if allowsSimulatedExternalCheckout {
            return PaymentMethod.allCases
        }
        // 上线前外部通道未就绪：仅余额（本机账本）。
        return [.wallet]
    }

    static var externalCheckoutUnavailableMessage: String {
        "外部支付通道接入中。当前可使用钱包余额；Apple Pay / 微信 / 支付宝将在正式通道就绪后开放。"
    }

    static var refundPendingServerMessage: String {
        "退款申请已提交，到账结果以支付服务商与运营审核为准。"
    }

    static var checkoutFooterSupplement: String {
        #if DEBUG
        "DEBUG：外部支付为本地模拟到账，非真实扣款。"
        #else
        "数字内容请走 App Store；线下服务费用当前支持钱包余额。"
        #endif
    }
}
