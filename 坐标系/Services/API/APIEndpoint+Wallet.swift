//
//  APIEndpoint+Wallet.swift
//  坐标系
//
//  钱包 / 充值 / 扣款 / 退款远程契约（跟 `useRemoteWallet`；默认关）。
//

import CoordinateModels
import CoordinateNetworking
import Foundation

extension APIEndpoint where Response == WalletAccountDTO {
    static var walletAccount: APIEndpoint<WalletAccountDTO> {
        APIEndpoint(path: "v1/wallet")
    }
}

extension APIEndpoint where Response == WalletLedgerPageDTO {
    static func walletLedger(cursor: String? = nil) -> APIEndpoint<WalletLedgerPageDTO> {
        if let cursor, !cursor.isEmpty {
            let encoded = cursor.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cursor
            return APIEndpoint(path: "v1/wallet/ledger?cursor=\(encoded)")
        }
        return APIEndpoint(path: "v1/wallet/ledger")
    }
}

extension APIEndpoint where Response == WalletTopUpIntentDTO {
    static func createWalletTopUp(_ body: WalletTopUpCreateBody) throws -> APIEndpoint<WalletTopUpIntentDTO> {
        APIEndpoint(
            path: "v1/wallet/topups",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }

    static func walletTopUpStatus(id: UUID) -> APIEndpoint<WalletTopUpIntentDTO> {
        APIEndpoint(path: "v1/wallet/topups/\(id.uuidString.lowercased())")
    }
}

extension APIEndpoint where Response == WalletChargeResultDTO {
    static func walletCharge(_ body: WalletChargeBody) throws -> APIEndpoint<WalletChargeResultDTO> {
        APIEndpoint(
            path: "v1/commerce/charges",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }
}

extension APIEndpoint where Response == WalletRefundCaseDTO {
    static func walletRefund(_ body: WalletRefundCreateBody) throws -> APIEndpoint<WalletRefundCaseDTO> {
        APIEndpoint(
            path: "v1/commerce/refunds",
            method: .post,
            body: try JSONEncoder().encode(body)
        )
    }
}
