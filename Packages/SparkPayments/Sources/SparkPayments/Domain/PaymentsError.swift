// Module: SparkPayments — Typed payment errors.

import Foundation
import SparkCore

public enum PaymentsError: LocalizedError, Sendable, Equatable {
    case productNotFound
    case userCancelled
    case pending
    case verificationFailed
    case providerNotConfigured(CNPaymentProvider)
    case cnPaymentUnavailable
    case underlying(AppError)

    public var errorDescription: String? {
        switch self {
        case .productNotFound:
            String(localized: "payments.error.productNotFound", defaultValue: "未找到订阅商品", comment: "Payments error")
        case .userCancelled:
            String(localized: "payments.error.cancelled", defaultValue: "已取消购买", comment: "Payments error")
        case .pending:
            String(localized: "payments.error.pending", defaultValue: "购买待处理", comment: "Payments error")
        case .verificationFailed:
            String(localized: "payments.error.verification", defaultValue: "购买验证失败", comment: "Payments error")
        case let .providerNotConfigured(provider):
            providerNotConfiguredMessage(for: provider)
        case .cnPaymentUnavailable:
            String(
                localized: "payments.error.cnPaymentUnavailable",
                defaultValue: "当前无法使用微信或支付宝支付，请稍后再试",
                comment: "Payments error"
            )
        case let .underlying(appError):
            appError.errorDescription
        }
    }

    private func providerNotConfiguredMessage(for provider: CNPaymentProvider) -> String {
        switch provider {
        case .wechat:
            String(
                localized: "payments.error.providerNotConfigured.wechat",
                defaultValue: "微信支付尚未配置",
                comment: "Payments error"
            )
        case .alipay:
            String(
                localized: "payments.error.providerNotConfigured.alipay",
                defaultValue: "支付宝支付尚未配置",
                comment: "Payments error"
            )
        }
    }
}
