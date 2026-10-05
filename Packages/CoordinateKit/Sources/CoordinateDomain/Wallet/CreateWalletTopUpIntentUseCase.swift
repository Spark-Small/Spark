//
//  CreateWalletTopUpIntentUseCase.swift
//  CoordinateDomain
//
//  创建充值意图前的校验（金额 / 渠道 / 青年模式）。
//

import Foundation

public enum WalletTopUpIntentFailure: String, Sendable, Equatable {
    case invalidAmount = "invalid_amount"
    case channelUnavailable = "channel_unavailable"
    case youthBlocked = "youth_blocked"
    case remoteDisabled = "remote_disabled"
}

public enum WalletTopUpIntentEvaluation: Sendable, Equatable {
    case ready(amountCents: Int, channel: String)
    case failure(WalletTopUpIntentFailure)
}

public struct CreateWalletTopUpIntentUseCase: Sendable {
    public init() {}

    public func evaluate(
        amountCents: Int,
        channel: String,
        allowsRemoteTopUp: Bool,
        allowsDemoTopUp: Bool,
        youthBlocked: Bool
    ) -> WalletTopUpIntentEvaluation {
        if youthBlocked {
            return .failure(.youthBlocked)
        }
        guard WalletMoneyPolicy.isValidTopUpAmount(amountCents) else {
            return .failure(.invalidAmount)
        }
        let normalized = channel.lowercased()
        if allowsDemoTopUp {
            return .ready(amountCents: amountCents, channel: normalized)
        }
        guard allowsRemoteTopUp else {
            return .failure(.remoteDisabled)
        }
        guard WalletMoneyPolicy.remoteTopUpChannels.contains(normalized) else {
            return .failure(.channelUnavailable)
        }
        return .ready(amountCents: amountCents, channel: normalized)
    }
}
