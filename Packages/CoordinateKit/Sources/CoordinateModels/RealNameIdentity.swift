//
//  RealNameIdentity.swift
//  CoordinateModels
//
//  实名认证：本机证件识别结果（不存证件号明文）。
//

import Foundation

/// 实名状态（对外徽章 / 编辑页只读门闸）。
public enum RealNameVerificationStatus: String, Codable, Hashable, Sendable {
    /// 未完成
    case unverified
    /// 本机已从证件识别并写入性别/出生日期（非公安库核验）
    case localVerified
}

/// 实名可用证件类型（选择器用滚轮）。
public enum RealNameDocumentKind: String, Codable, Hashable, Sendable, CaseIterable, Identifiable {
    case chineseResidentID
    case passport

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .chineseResidentID: "居民身份证"
        case .passport: "护照"
        }
    }
}

public struct RealNameDemographicsResult: Hashable, Sendable {
    public var documentKind: RealNameDocumentKind
    public var gender: ProfileGender
    public var birthDate: Date
    public var age: Int
    public var idNumberFingerprint: String
    public var idNumberMasked: String

    public init(
        documentKind: RealNameDocumentKind,
        gender: ProfileGender,
        birthDate: Date,
        age: Int,
        idNumberFingerprint: String,
        idNumberMasked: String
    ) {
        self.documentKind = documentKind
        self.gender = gender
        self.birthDate = birthDate
        self.age = age
        self.idNumberFingerprint = idNumberFingerprint
        self.idNumberMasked = idNumberMasked
    }
}
