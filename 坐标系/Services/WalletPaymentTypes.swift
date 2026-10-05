//
//  WalletPaymentTypes.swift
//  坐标系
//
//  支付方式、账本条目与支付结果类型。
//

import Foundation
import CoordinateModels

enum PaymentMethod: String, Codable, CaseIterable, Hashable, Identifiable {
    case wallet
    case applePay
    case wechat
    case alipay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .wallet: "余额支付"
        case .applePay: "Apple Pay"
        case .wechat: "微信支付"
        case .alipay: "支付宝"
        }
    }

    var systemImage: String {
        switch self {
        case .wallet: "wallet.bifold.fill"
        case .applePay: "applelogo"
        case .wechat: "message.fill"
        case .alipay: "yensign.circle.fill"
        }
    }

    /// 是否扣 / 退应用内余额
    var affectsWalletBalance: Bool { self == .wallet }

    static func resolve(_ raw: String) -> PaymentMethod {
        if let exact = PaymentMethod(rawValue: raw) { return exact }
        switch raw {
        case "余额支付", "wallet", "simulated": return .wallet
        case "Apple Pay", "applePay": return .applePay
        case "微信支付", "wechat": return .wechat
        case "支付宝", "alipay": return .alipay
        default: return .applePay
        }
    }
}

enum WalletEntryKind: String, Codable, Hashable {
    case topUp
    case welcome
    case activityPayment
    case activityRefund
    case bookingPayment
    case bookingRefund
    case transferOut
    case transferIn
    case transferRefund
    case membership

    /// 远程 `kind` → 本地枚举；未知值回落充值/支付语义，避免丢行。
    static func resolve(_ raw: String) -> WalletEntryKind {
        if let exact = WalletEntryKind(rawValue: raw) { return exact }
        switch raw.lowercased() {
        case "topup", "top_up", "credit": return .topUp
        case "welcome", "gift": return .welcome
        case "activity", "activity_payment", "activitypayment": return .activityPayment
        case "activity_refund", "activityrefund": return .activityRefund
        case "booking", "booking_payment", "bookingpayment": return .bookingPayment
        case "booking_refund", "bookingrefund": return .bookingRefund
        case "transfer_out", "transferout": return .transferOut
        case "transfer_in", "transferin": return .transferIn
        case "transfer_refund", "transferrefund": return .transferRefund
        case "membership", "vip": return .membership
        default: return .topUp
        }
    }

    var titleFallback: String {
        switch self {
        case .topUp: "充值"
        case .welcome: "开户赠送"
        case .activityPayment: "活动支付"
        case .activityRefund: "活动退款"
        case .bookingPayment: "陪玩支付"
        case .bookingRefund: "陪玩退款"
        case .transferOut: "转账支出"
        case .transferIn: "转账收款"
        case .transferRefund: "转账退回"
        case .membership: "会员开通"
        }
    }

    var systemImage: String {
        switch self {
        case .topUp, .welcome: "plus.circle.fill"
        case .activityPayment, .activityRefund: "calendar"
        case .bookingPayment, .bookingRefund: "person.2.fill"
        case .transferOut, .transferIn, .transferRefund: "yensign.circle.fill"
        case .membership: "checkmark.seal.fill"
        }
    }
}

struct WalletLedgerEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let kind: WalletEntryKind
    let title: String
    var subtitle: String?
    /// 对余额的影响：支出为负、收入为正；外部支付可为 0
    let balanceDeltaCents: Int
    /// 业务金额（始终为正），用于展示
    let amountCents: Int
    let method: PaymentMethod
    let createdAt: Date
    var relatedID: UUID?

    var isCredit: Bool { balanceDeltaCents > 0 || (balanceDeltaCents == 0 && kind == .transferIn) }
}

enum PaymentOutcome: Equatable {
    case success
    case insufficientBalance
    case failed(String)
}

