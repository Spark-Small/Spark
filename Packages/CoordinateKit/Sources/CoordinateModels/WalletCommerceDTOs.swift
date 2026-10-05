//
//  WalletCommerceDTOs.swift
//  CoordinateModels
//
//  钱包 / 支付远程契约 DTO（与 Project/09 对齐；后端未通时仅客户端解码）。
//

import Foundation

public struct WalletAccountDTO: Codable, Hashable, Sendable {
    public var availableCents: Int
    public var frozenCents: Int
    public var currency: String
    public var version: Int

    public init(
        availableCents: Int,
        frozenCents: Int = 0,
        currency: String = "CNY",
        version: Int = 0
    ) {
        self.availableCents = availableCents
        self.frozenCents = frozenCents
        self.currency = currency
        self.version = version
    }
}

public struct WalletLedgerPageDTO: Codable, Hashable, Sendable {
    public var items: [WalletLedgerItemDTO]
    public var nextCursor: String?

    public init(items: [WalletLedgerItemDTO], nextCursor: String? = nil) {
        self.items = items
        self.nextCursor = nextCursor
    }
}

public struct WalletLedgerItemDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var kind: String
    public var title: String
    public var deltaCents: Int
    public var amountCents: Int
    public var balanceAfterCents: Int?
    public var channel: String?
    public var relatedID: UUID?
    public var createdAt: Date
    public var idempotencyKey: String?

    public init(
        id: UUID,
        kind: String,
        title: String,
        deltaCents: Int,
        amountCents: Int,
        balanceAfterCents: Int? = nil,
        channel: String? = nil,
        relatedID: UUID? = nil,
        createdAt: Date,
        idempotencyKey: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.deltaCents = deltaCents
        self.amountCents = amountCents
        self.balanceAfterCents = balanceAfterCents
        self.channel = channel
        self.relatedID = relatedID
        self.createdAt = createdAt
        self.idempotencyKey = idempotencyKey
    }
}

public struct WalletTopUpCreateBody: Codable, Hashable, Sendable {
    public var amountCents: Int
    public var channel: String
    public var idempotencyKey: String

    public init(amountCents: Int, channel: String, idempotencyKey: String) {
        self.amountCents = amountCents
        self.channel = channel
        self.idempotencyKey = idempotencyKey
    }
}

public struct WalletTopUpIntentDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var amountCents: Int
    public var channel: String
    public var status: String
    /// 调起 SDK 所需不透明载荷（后端下发；客户端不解析业务语义）。
    public var clientPayload: String?
    public var createdAt: Date?

    public init(
        id: UUID,
        amountCents: Int,
        channel: String,
        status: String,
        clientPayload: String? = nil,
        createdAt: Date? = nil
    ) {
        self.id = id
        self.amountCents = amountCents
        self.channel = channel
        self.status = status
        self.clientPayload = clientPayload
        self.createdAt = createdAt
    }

    public var isSucceeded: Bool {
        status == "succeeded" || status == "credited"
    }

    public var isFailed: Bool {
        status == "failed" || status == "expired"
    }
}

public struct WalletChargeBody: Codable, Hashable, Sendable {
    public var amountCents: Int
    public var orderType: String
    public var orderID: UUID
    public var idempotencyKey: String

    public init(amountCents: Int, orderType: String, orderID: UUID, idempotencyKey: String) {
        self.amountCents = amountCents
        self.orderType = orderType
        self.orderID = orderID
        self.idempotencyKey = idempotencyKey
    }
}

public struct WalletChargeResultDTO: Codable, Hashable, Sendable {
    public var account: WalletAccountDTO
    public var ledgerEntryID: UUID?

    public init(account: WalletAccountDTO, ledgerEntryID: UUID? = nil) {
        self.account = account
        self.ledgerEntryID = ledgerEntryID
    }
}

public struct WalletRefundCreateBody: Codable, Hashable, Sendable {
    public var orderType: String
    public var orderID: UUID
    public var amountCents: Int
    public var reason: String
    public var idempotencyKey: String

    public init(
        orderType: String,
        orderID: UUID,
        amountCents: Int,
        reason: String,
        idempotencyKey: String
    ) {
        self.orderType = orderType
        self.orderID = orderID
        self.amountCents = amountCents
        self.reason = reason
        self.idempotencyKey = idempotencyKey
    }
}

public struct WalletRefundCaseDTO: Codable, Hashable, Sendable, Identifiable {
    public var id: UUID
    public var status: String
    public var orderID: UUID
    public var amountCents: Int

    public init(id: UUID, status: String, orderID: UUID, amountCents: Int) {
        self.id = id
        self.status = status
        self.orderID = orderID
        self.amountCents = amountCents
    }
}
