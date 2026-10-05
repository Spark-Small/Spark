//
//  CommercePaymentPolicy.swift
//  坐标系
//
//  支付 / 退款演示边界（Apple 审核 3.1.1 / 2.3.1：不得伪造 Apple Pay 等到账）。
//

import CoordinateFeatureFlags
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

    /// 远程钱包 Flag（契约已备；默认关）。开启后充值走服务端意图，禁止本地假入账。
    static var allowsRemoteWallet: Bool {
        FeatureFlags.useRemoteWallet
    }

    /// Release 退款不自动 sleep 完结，保持「已提交 / 处理中」等服务端确认。
    static var simulatesLocalRefundCompletion: Bool {
        #if DEBUG
        !allowsRemoteWallet
        #else
        false
        #endif
    }

    /// 结账页可选支付方式。
    static var checkoutMethods: [PaymentMethod] {
        if allowsSimulatedExternalCheckout {
            return PaymentMethod.allCases
        }
        // 上线前外部通道未就绪：仅余额（本机账本或远程账本投影）。
        return [.wallet]
    }

    /// 充值可选渠道：演示可含 Apple Pay；远程仅微信/支付宝；否则空。
    static var topUpMethods: [PaymentMethod] {
        if allowsSimulatedExternalCheckout {
            return [.applePay, .wechat, .alipay]
        }
        if allowsRemoteWallet {
            return [.wechat, .alipay]
        }
        return []
    }

    static var canAttemptTopUp: Bool {
        allowsSimulatedExternalCheckout || allowsRemoteWallet
    }

    static var externalCheckoutUnavailableMessage: String {
        "外部支付通道接入中。当前可使用钱包余额；Apple Pay / 微信 / 支付宝将在正式通道就绪后开放。"
    }

    static var remoteWalletUnavailableMessage: String {
        "远程钱包服务暂不可用。请稍后重试；未确认到账前不会增加余额。"
    }

    static var refundPendingServerMessage: String {
        "退款申请已提交，到账结果以支付服务商与运营审核为准。"
    }

    static var withdrawNotOpenMessage: String {
        "提现尚未开放。正式版将接入实名与结算通道；当前不会发起真实出款。"
    }

    static var invoiceNotOpenMessage: String {
        "电子发票尚未开放。正式版将提供开票中心；当前不会生成真实发票。"
    }

    /// 结账主路径首屏披露（比 footer 更醒目，对齐审核诚实披露）。
    static var checkoutDisclosure: String {
        #if DEBUG
        if allowsRemoteWallet {
            return "DEBUG：已开 useRemoteWallet，扣款/充值以服务端为准；失败不会本地假入账。"
        }
        return "当前为本地演示扣款：钱包为设备账本；外部支付方式为模拟到账，不会真实扣款。"
        #else
        if allowsRemoteWallet {
            return "钱包余额以服务端账本为准。线下活动费用支持余额支付；充值经微信/支付宝正式通道入账。"
        }
        return "钱包余额为设备本地账本。线下活动费用当前仅支持余额；Apple Pay / 微信 / 支付宝将在正式通道就绪后开放。"
        #endif
    }

    static var checkoutFooterSupplement: String {
        checkoutDisclosure
    }

    static var topUpFooterDisclosure: String {
        #if DEBUG
        if allowsRemoteWallet {
            return "DEBUG：远程充值意图；到账以轮询/回调为准，禁止未确认本地加款。"
        }
        return "DEBUG：本地演示充值，立即记入钱包余额。"
        #else
        if allowsRemoteWallet {
            return "充值经微信/支付宝正式通道；到账以服务端确认为准。"
        }
        return "正式充值通道接入中。数字商品请通过 App Store；线下服务将走合规支付。"
        #endif
    }
}
