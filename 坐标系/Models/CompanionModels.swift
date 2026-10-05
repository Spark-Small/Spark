//
//  CompanionModels.swift
//  坐标系
//
//  陪玩、工会与语音厅模型。
//

import Foundation
import SwiftUI
import CoordinateModels

enum CompanionPricingUnit: String, CaseIterable, Identifiable, Hashable, Sendable {
    case halfHour = "30分钟"
    case hour = "小时"
    case session = "次"
    case day = "天"

    var id: String { rawValue }

    var priceSuffix: String {
        switch self {
        case .halfHour: "/30分钟"
        case .hour: "/小时"
        case .session: "/次"
        case .day: "/天"
        }
    }
}

enum CompanionServiceType: String, CaseIterable, Identifiable, Hashable {
    case voice = "语音陪聊"
    case sport = "运动陪练"
    case offline = "线下见面"
    case photo = "拍照跟拍"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .voice: "waveform"
        case .sport: "figure.run"
        case .offline: "mappin.and.ellipse"
        case .photo: "camera"
        }
    }

    /// 列表价默认计价单位（主流：语音按 30 分钟，运动/线下按小时，跟拍可次或小时）
    var defaultPricingUnit: CompanionPricingUnit {
        switch self {
        case .voice: .halfHour
        case .sport, .offline: .hour
        case .photo: .hour
        }
    }
}

enum CompanionPricing {
    /// 按天等项目：双方私信商议，平台不锁价
    static let negotiable = "双方商议"

    static func format(amount: Int, unit: CompanionPricingUnit) -> String {
        "¥\(amount)\(unit.priceSuffix)"
    }

    static func pack(amount: Int, label: String) -> String {
        "¥\(amount)\(label)"
    }
}

struct PaidCompanion: Identifiable, Hashable {
    var profile: BuddyProfile
    var serviceType: CompanionServiceType
    var specialty: String
    /// 基准价：配合 `pricingUnit` 展示（如 39 + halfHour = ¥39/30分钟）
    var hourlyPrice: Int
    var pricingUnit: CompanionPricingUnit
    var orderCount: Int
    var isAvailable: Bool
    var responseTime: String
    var scheduleSlots: [String]
    var relatedActivityTitles: [String]
    /// 平台认证（演示角标）
    var isVerified: Bool

    var id: UUID { profile.id }
    var priceText: String { CompanionPricing.format(amount: hourlyPrice, unit: pricingUnit) }

    init(
        profile: BuddyProfile,
        serviceType: CompanionServiceType,
        specialty: String,
        hourlyPrice: Int,
        pricingUnit: CompanionPricingUnit? = nil,
        orderCount: Int,
        isAvailable: Bool,
        responseTime: String,
        scheduleSlots: [String],
        relatedActivityTitles: [String],
        isVerified: Bool = true
    ) {
        self.profile = profile
        self.serviceType = serviceType
        self.specialty = specialty
        self.hourlyPrice = hourlyPrice
        self.pricingUnit = pricingUnit ?? serviceType.defaultPricingUnit
        self.orderCount = orderCount
        self.isAvailable = isAvailable
        self.responseTime = responseTime
        self.scheduleSlots = scheduleSlots
        self.relatedActivityTitles = relatedActivityTitles
        self.isVerified = isVerified
    }
}

/// 陪玩工会：商业侧的「圈子」，与免费兴趣圈对位
struct CompanionGuild: Identifiable, Hashable {
    let id: UUID
    var name: String
    var specialty: String
    var city: String
    var companionCount: Int
    var weeklyOrders: Int
    var priceFrom: Int
    var tags: [String]
    var summary: String
    var isJoined: Bool
    var systemImage: String

    var priceFromText: String { "¥\(priceFrom) 起" }
}

/// 陪玩语音厅（用户侧场；不对用户开放「工会入会」）
struct VoiceHall: Identifiable, Hashable {
    let id: UUID
    var title: String
    var topic: String
    var city: String
    var hostNickname: String
    /// 麦上昵称（含厅主）
    var onMicNicknames: [String]
    var listenerCount: Int
    var tagline: String
    var systemImage: String
    var isLive: Bool

    var audienceText: String {
        "\(onMicNicknames.count) 麦上 · \(listenerCount) 围观"
    }
}

