//
//  PassModels.swift
//  坐标系
//
//  Pass 数据定义：对齐 Apple pass.json 关键键与本机生命周期状态。
//

import Foundation
import CoordinateModels

enum PassStyle: String, Codable, Hashable, CaseIterable {
    case eventTicket
    case storeCard
    case coupon

    var displayName: String {
        switch self {
        case .eventTicket: "活动凭证"
        case .storeCard: "会员卡"
        case .coupon: "优惠券"
        }
    }

    var systemImage: String {
        switch self {
        case .eventTicket: "ticket"
        case .storeCard: "person.text.rectangle"
        case .coupon: "tag"
        }
    }

    var passJSONKey: String { rawValue }
}

struct PassField: Codable, Hashable, Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let value: String
}

/// 分发通道状态（App 侧跟踪，非 pass.json 字段）。
enum PassDistributionState: String, Codable, Hashable, CaseIterable {
    case draft
    case ready
    case exported
    case inSystemWallet

    var displayName: String {
        switch self {
        case .draft: "草稿"
        case .ready: "可分发"
        case .exported: "已导出"
        case .inSystemWallet: "已在系统 Wallet"
        }
    }
}

/// Source 层产出的稳定草稿（签发前）。
struct PassDraft: Hashable {
    let style: PassStyle
    let serialNumber: String
    let description: String
    let headerFields: [PassField]
    let primaryFields: [PassField]
    let secondaryFields: [PassField]
    let auxiliaryFields: [PassField]
    let backFields: [PassField]
    let barcodeMessage: String
    let relevantDate: Date?
    let expirationDate: Date?
    let relatedID: UUID?
    /// 活动分类等，用于 strip / background 配色。
    let appearanceKey: String?
    let backgroundColorRGB: String?
}

/// 已签发通行证记录（权威本地副本；更新保持 serial + authenticationToken）。
struct PassRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let style: PassStyle
    let serialNumber: String
    let description: String
    var headerFields: [PassField]
    var primaryFields: [PassField]
    var secondaryFields: [PassField]
    var auxiliaryFields: [PassField]
    var backFields: [PassField]
    let barcodeMessage: String
    var relevantDate: Date?
    var expirationDate: Date?
    let relatedID: UUID?
    let createdAt: Date
    /// 官方：更新 Web Service 鉴权；签发后不变。
    let authenticationToken: String
    /// 官方：`passesUpdatedSince` 用的 lastUpdated 标签。
    var lastUpdated: Date
    /// 官方 pass.json `voided`。
    var voided: Bool
    var distributionState: PassDistributionState
    var addedToSystemWallet: Bool
    var appearanceKey: String?
    var backgroundColorRGB: String?

    var title: String {
        primaryFields.first?.value ?? description
    }

    /// 按 key 在 primary / secondary / auxiliary 中查找字段。
    func field(key: String) -> PassField? {
        headerFields.first(where: { $0.key == key })
            ?? primaryFields.first(where: { $0.key == key })
            ?? secondaryFields.first(where: { $0.key == key })
            ?? auxiliaryFields.first(where: { $0.key == key })
    }

    var passTypeIdentifier: String { PassConfiguration.passTypeIdentifier }

    var webServiceURL: String { PassConfiguration.webServiceURL }

    /// 供更新协议返回的 lastUpdated 字符串标签。
    var lastUpdatedTag: String {
        PassDateFormatting.tag(from: lastUpdated)
    }

    enum CodingKeys: String, CodingKey {
        case id, style, serialNumber, description
        case headerFields, primaryFields, secondaryFields, auxiliaryFields, backFields
        case barcodeMessage, relevantDate, expirationDate, relatedID, createdAt
        case authenticationToken, lastUpdated, voided, distributionState, addedToSystemWallet
        case appearanceKey, backgroundColorRGB
    }

    init(
        id: UUID = UUID(),
        style: PassStyle,
        serialNumber: String,
        description: String,
        headerFields: [PassField] = [],
        primaryFields: [PassField],
        secondaryFields: [PassField],
        auxiliaryFields: [PassField],
        backFields: [PassField],
        barcodeMessage: String,
        relevantDate: Date?,
        expirationDate: Date?,
        relatedID: UUID?,
        createdAt: Date = .now,
        authenticationToken: String = PassRecord.makeAuthenticationToken(),
        lastUpdated: Date = .now,
        voided: Bool = false,
        distributionState: PassDistributionState = .ready,
        addedToSystemWallet: Bool = false,
        appearanceKey: String? = nil,
        backgroundColorRGB: String? = nil
    ) {
        self.id = id
        self.style = style
        self.serialNumber = serialNumber
        self.description = description
        self.headerFields = headerFields
        self.primaryFields = primaryFields
        self.secondaryFields = secondaryFields
        self.auxiliaryFields = auxiliaryFields
        self.backFields = backFields
        self.barcodeMessage = barcodeMessage
        self.relevantDate = relevantDate
        self.expirationDate = expirationDate
        self.relatedID = relatedID
        self.createdAt = createdAt
        self.authenticationToken = authenticationToken
        self.lastUpdated = lastUpdated
        self.voided = voided
        self.distributionState = distributionState
        self.addedToSystemWallet = addedToSystemWallet
        self.appearanceKey = appearanceKey
        self.backgroundColorRGB = backgroundColorRGB
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        style = try c.decode(PassStyle.self, forKey: .style)
        serialNumber = try c.decode(String.self, forKey: .serialNumber)
        description = try c.decode(String.self, forKey: .description)
        headerFields = try c.decodeIfPresent([PassField].self, forKey: .headerFields) ?? []
        primaryFields = try c.decode([PassField].self, forKey: .primaryFields)
        secondaryFields = try c.decode([PassField].self, forKey: .secondaryFields)
        auxiliaryFields = try c.decode([PassField].self, forKey: .auxiliaryFields)
        backFields = try c.decode([PassField].self, forKey: .backFields)
        barcodeMessage = try c.decode(String.self, forKey: .barcodeMessage)
        relevantDate = try c.decodeIfPresent(Date.self, forKey: .relevantDate)
        expirationDate = try c.decodeIfPresent(Date.self, forKey: .expirationDate)
        relatedID = try c.decodeIfPresent(UUID.self, forKey: .relatedID)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        authenticationToken = try c.decodeIfPresent(String.self, forKey: .authenticationToken)
            ?? PassRecord.makeAuthenticationToken()
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? createdAt
        voided = try c.decodeIfPresent(Bool.self, forKey: .voided) ?? false
        distributionState = try c.decodeIfPresent(PassDistributionState.self, forKey: .distributionState)
            ?? (try c.decodeIfPresent(Bool.self, forKey: .addedToSystemWallet) == true
                ? .inSystemWallet
                : .ready)
        addedToSystemWallet = try c.decodeIfPresent(Bool.self, forKey: .addedToSystemWallet) ?? false
        appearanceKey = try c.decodeIfPresent(String.self, forKey: .appearanceKey)
        backgroundColorRGB = try c.decodeIfPresent(String.self, forKey: .backgroundColorRGB)
    }

    static func from(draft: PassDraft) -> PassRecord {
        PassRecord(
            style: draft.style,
            serialNumber: draft.serialNumber,
            description: draft.description,
            headerFields: draft.headerFields,
            primaryFields: draft.primaryFields,
            secondaryFields: draft.secondaryFields,
            auxiliaryFields: draft.auxiliaryFields,
            backFields: draft.backFields,
            barcodeMessage: draft.barcodeMessage,
            relevantDate: draft.relevantDate,
            expirationDate: draft.expirationDate,
            relatedID: draft.relatedID,
            appearanceKey: draft.appearanceKey,
            backgroundColorRGB: draft.backgroundColorRGB
        )
    }

    static func makeAuthenticationToken() -> String {
        Data((0..<16).map { _ in UInt8.random(in: 0...255) })
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

enum PassDateFormatting {
    static func tag(from date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    static func date(from tag: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: tag)
    }
}
