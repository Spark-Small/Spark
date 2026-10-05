//
//  RemoteWalletClient.swift
//  坐标系
//
//  远程钱包客户端：仅当 `useRemoteWallet` 时打 API；失败诚实上抛，禁止本地假入账。
//

import CoordinateFeatureFlags
import CoordinateModels
import CoordinateNetworking
import Foundation

enum RemoteWalletError: LocalizedError {
    case remoteDisabled
    case topUpNotSucceeded
    case channelUnavailable

    var errorDescription: String? {
        switch self {
        case .remoteDisabled:
            "远程钱包未开启。请待支付服务就绪后再试。"
        case .topUpNotSucceeded:
            "充值尚未到账，请稍后在钱包查看或联系客服。"
        case .channelUnavailable:
            "该充值渠道暂不可用。"
        }
    }
}

@MainActor
enum RemoteWalletClient {
    private static var client: APIClient { .shared }

    static var isEnabled: Bool { FeatureFlags.useRemoteWallet }

    static func fetchAccount() async throws -> WalletAccountDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        return try await client.send(.walletAccount)
    }

    static func fetchLedger(cursor: String? = nil) async throws -> WalletLedgerPageDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        return try await client.send(.walletLedger(cursor: cursor))
    }

    static func createTopUp(amountCents: Int, channel: String) async throws -> WalletTopUpIntentDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        let body = WalletTopUpCreateBody(
            amountCents: amountCents,
            channel: channel,
            idempotencyKey: UUID().uuidString
        )
        return try await client.send(try .createWalletTopUp(body))
    }

    static func topUpStatus(id: UUID) async throws -> WalletTopUpIntentDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        return try await client.send(.walletTopUpStatus(id: id))
    }

    /// 轮询充值意图直至成功 / 失败 / 超时（不本地加余额）。
    static func awaitTopUpCredit(
        id: UUID,
        attempts: Int = 8,
        intervalNanoseconds: UInt64 = 500_000_000
    ) async throws -> WalletTopUpIntentDTO {
        var last: WalletTopUpIntentDTO?
        for _ in 0..<attempts {
            let intent = try await topUpStatus(id: id)
            last = intent
            if intent.isSucceeded { return intent }
            if intent.isFailed { throw RemoteWalletError.topUpNotSucceeded }
            try await Task.sleep(nanoseconds: intervalNanoseconds)
        }
        if let last, last.isSucceeded { return last }
        throw RemoteWalletError.topUpNotSucceeded
    }

    static func charge(
        amountCents: Int,
        orderType: String,
        orderID: UUID
    ) async throws -> WalletChargeResultDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        let body = WalletChargeBody(
            amountCents: amountCents,
            orderType: orderType,
            orderID: orderID,
            idempotencyKey: "\(orderType)-\(orderID.uuidString.lowercased())-\(amountCents)"
        )
        return try await client.send(try .walletCharge(body))
    }

    static func submitRefund(
        orderType: String,
        orderID: UUID,
        amountCents: Int,
        reason: String
    ) async throws -> WalletRefundCaseDTO {
        guard isEnabled else { throw RemoteWalletError.remoteDisabled }
        let body = WalletRefundCreateBody(
            orderType: orderType,
            orderID: orderID,
            amountCents: amountCents,
            reason: reason,
            idempotencyKey: "refund-\(orderType)-\(orderID.uuidString.lowercased())"
        )
        return try await client.send(try .walletRefund(body))
    }
}
