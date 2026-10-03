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

    /// 结账主路径首屏披露（比 footer 更醒目，对齐审核诚实披露）。
    static var checkoutDisclosure: String {
        #if DEBUG
        "当前为本地演示扣款：钱包为设备账本；外部支付方式为模拟到账，不会真实扣款。"
        #else
        "钱包余额为设备本地账本。线下活动费用当前仅支持余额；Apple Pay / 微信 / 支付宝将在正式通道就绪后开放。"
        #endif
    }

    static var checkoutFooterSupplement: String {
        checkoutDisclosure
    }
}
