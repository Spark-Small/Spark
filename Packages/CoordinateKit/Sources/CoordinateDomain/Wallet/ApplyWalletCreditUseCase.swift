//
//  ApplyWalletCreditUseCase.swift
//  CoordinateDomain
//
//  入账 delta 规则：充值/转账收款始终入账；退款仅余额支付加回。
//

import Foundation

public enum WalletCreditKind: String, Sendable, Equatable {
    case topUp
    case welcome
    case transferIn
    case activityRefund
    case bookingRefund
    case transferRefund
    case other
}

public struct ApplyWalletCreditUseCase: Sendable {
    public init() {}

    /// 返回应加到余额的分（可为 0：仅记流水）。
    public func balanceDeltaCents(
        amountCents: Int,
        kind: WalletCreditKind,
        methodAffectsBalance: Bool
    ) -> Int {
        guard amountCents > 0 else { return 0 }
        switch kind {
        case .topUp, .welcome, .transferIn:
            return amountCents
        case .activityRefund, .bookingRefund, .transferRefund:
            return methodAffectsBalance ? amountCents : 0
        case .other:
            return methodAffectsBalance ? amountCents : 0
        }
    }
}
