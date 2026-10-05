//
//  ChargeWalletUseCase.swift
//  CoordinateDomain
//
//  扣款合法性与新余额计算（纯规则；落账由 Repository / Store）。
//

import Foundation

public enum ChargeWalletFailureReason: String, Sendable, Equatable {
    case invalidAmount = "invalid_amount"
    case externalUnavailable = "external_unavailable"
    case insufficientBalance = "insufficient_balance"
}

public enum ChargeWalletEvaluation: Sendable, Equatable {
    case success(newBalanceCents: Int, balanceDeltaCents: Int)
    case failure(ChargeWalletFailureReason)
}

public struct ChargeWalletUseCase: Sendable {
    public init() {}

    public func evaluate(
        balanceCents: Int,
        amountCents: Int,
        methodAffectsBalance: Bool,
        isExternalMethod: Bool,
        allowsSimulatedExternal: Bool
    ) -> ChargeWalletEvaluation {
        guard amountCents > 0 else {
            return .failure(.invalidAmount)
        }
        if isExternalMethod, !allowsSimulatedExternal {
            return .failure(.externalUnavailable)
        }
        if methodAffectsBalance {
            guard balanceCents >= amountCents else {
                return .failure(.insufficientBalance)
            }
            return .success(
                newBalanceCents: balanceCents - amountCents,
                balanceDeltaCents: -amountCents
            )
        }
        return .success(newBalanceCents: balanceCents, balanceDeltaCents: 0)
    }
}
