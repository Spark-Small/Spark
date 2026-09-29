//
//  Models.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import Foundation
import SwiftUI
import CoordinateModels

/// 全时段筛选 UI 见 `ActivityQuickFilter+UI.swift`；类型定义在 CoordinateModels。

enum BuddyKind: String, CaseIterable, Identifiable {
    case free = "搭子"
    case paid = "陪玩"

    var id: String { rawValue }

    /// 顶栏分段与页面标题
    var stageTitle: String {
        switch self {
        case .free: "找搭子"
        case .paid: "约陪玩"
        }
    }

    var systemImage: String {
        switch self {
        case .free: "person.2"
        case .paid: "chineseyuanrenminbisign"
        }
    }
}

struct BuddyFilter: Equatable {
    /// 搭子页默认免费找人；`.paid` 为花钱预约
    var kind: BuddyKind = .free
    var gender: BuddyGender?
    var maxDistanceKM: Double = 20
    var hobby: String?
    /// 开放域搜索：昵称 / 我想… / 兴趣 / 擅长（不是产品场景枚举）
    var query: String = ""
    /// 预约服务类型；`nil` = 全部
    var serviceType: CompanionServiceType?
    var availableOnly = false

    /// 发现条件是否为默认（不含免费/预约切换）
    var isDefault: Bool {
        gender == nil
            && maxDistanceKM >= 20
            && hobby == nil
            && query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && serviceType == nil
            && !availableOnly
    }

    mutating func reset() {
        let currentKind = kind
        self = BuddyFilter(kind: currentKind)
    }
}

/// 人列表排序：推荐 / 刚活跃（「附近」由首页分区承接）
enum BuddyPeopleSort: String, CaseIterable, Identifiable {
    case recommended = "推荐"
    case active = "刚活跃"

    var id: String { rawValue }
}

/// 预约列表排序：比价 / 抢档比搜词更常用
enum BuddyBookingSort: String, CaseIterable, Identifiable {
    case recommended = "推荐"
    case price = "价格"
    case earliest = "最早可约"

    var id: String { rawValue }
}

enum BuddyGender: String, CaseIterable, Hashable {
    case male = "男"
    case female = "女"

    var symbol: String {
        switch self {
        case .male: "♂"
        case .female: "♀"
        }
    }

    var tint: Color {
        switch self {
        case .male: .blue
        case .female: .red
        }
    }
}

struct BuddyProfile: Identifiable, Hashable {
    let id: UUID
    var nickname: String
    var gender: BuddyGender
    var age: Int
    var heightCM: Int
    var weightKG: Int
    var distanceKM: Double
    var photoSeeds: [Int]
    /// 本地 Assets 图集（优先于 seeded 占位）
    var photoAssetNames: [String] = []
    var city: String
    var bio: String
    var tags: [String]
    var availability: String
    var lastActiveText: String
    var lookingFor: String
    /// 对外语音介绍时长（秒）；nil 表示未录制。展示在搭子 / 陪玩资料页。
    var voiceIntroDuration: Double? = nil
    /// 语音条说明（可选）
    var voiceIntroCaption: String? = nil

    var heightText: String { "\(heightCM)cm" }
    var weightText: String { "\(weightKG)kg" }

    var distanceText: String {
        if distanceKM < 1 {
            return String(format: "%.0fm", distanceKM * 1000)
        }
        return String(format: "%.1fkm", distanceKM)
    }

    /// 与活动「附近」同一阈值，供搭子分区复用
    var isNearby: Bool { distanceKM <= RecommendationConfig.nearbyKM }

    var metricsText: String {
        "\(age)岁 · \(heightText) · \(weightText)"
    }

    var hobbiesText: String {
        tags.prefix(3).joined(separator: " · ")
    }

    var photoSymbol: String { "person.fill" }

    var photoRefs: [CommunityPhotoRef] {
        if !photoAssetNames.isEmpty {
            return photoAssetNames.map(CommunityPhotoRef.asset)
        }
        let seeds = photoSeeds.isEmpty ? [abs(id.hashValue % 9000) + 100] : photoSeeds
        return seeds.map { .seeded(seed: $0, symbol: photoSymbol) }
    }

    var coverPhoto: CommunityPhotoRef? { photoRefs.first }
}

enum BuddyHobbyOption: String, CaseIterable, Identifiable {
    case cycling = "骑行"
    case coffee = "咖啡"
    case hiking = "徒步"
    case food = "美食"
    case badminton = "羽毛球"
    case exhibition = "展览"
    case market = "市集"
    case photo = "摄影"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .cycling: "bicycle"
        case .coffee: "cup.and.saucer"
        case .hiking: "figure.hiking"
        case .food: "fork.knife"
        case .badminton: "figure.badminton"
        case .exhibition: "building.columns"
        case .market: "basket"
        case .photo: "camera"
        }
    }

    static func systemImage(for hobby: String?) -> String {
        guard let hobby,
              let option = BuddyHobbyOption.allCases.first(where: { $0.rawValue == hobby })
        else {
            return "heart"
        }
        return option.systemImage
    }
}

/// 兴趣圈子里的免费同好搭子
struct CircleBuddy: Identifiable, Hashable {
    var profile: BuddyProfile
    var circleName: String
    var topic: String
    var isOnline: Bool
    var scheduleSlots: [String]
    /// 与当前用户爱好匹配、可一起去的附近活动 id（示例用 title 关联）
    var relatedActivityTitles: [String]

    var id: UUID { profile.id }
}

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

extension CommunityPost {
    var isRepost: Bool { repostedFromID != nil }

    var messageText: String {
        if let quote = quoteText?.trimmingCharacters(in: .whitespacesAndNewlines), !quote.isEmpty {
            return quote
        }
        return body.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var shareText: String {
        "【坐标系·社区】\(messageText)"
    }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }

    var displayPhotos: [CommunityPhotoRef] {
        if !localPhotoNames.isEmpty {
            return localPhotoNames.compactMap { name in
                CommunityPhotoStore.fileURL(named: name).map(CommunityPhotoRef.file)
            }
        }
        let seeds = photoSeeds.isEmpty ? [abs(id.hashValue % 9000) + 200] : photoSeeds
        let symbol = tags.first.flatMap { BuddyHobbyOption(rawValue: $0)?.systemImage }
            ?? "sparkles"
        return seeds.map { .seeded(seed: $0, symbol: symbol) }
    }

    var coverPhoto: CommunityPhotoRef? { displayPhotos.first }
}

extension CommunityComment {
    var isReply: Bool { parentID != nil }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }
}

enum CommunityPhotoRef: Hashable {
    case remote(URL)
    case file(URL)
    case asset(String)
    case seeded(seed: Int, symbol: String)

    var isVideo: Bool {
        switch self {
        case .file(let url):
            return CommunityPhotoStore.isVideo(url: url)
        default:
            return false
        }
    }

    var videoURL: URL? {
        guard isVideo, case .file(let url) = self else { return nil }
        return url
    }
}

enum CommunityMediaCopy {
    static func countChip(_ refs: [CommunityPhotoRef]) -> String {
        let videos = refs.filter(\.isVideo).count
        let photos = refs.count - videos
        if videos == 0 { return "\(photos) 张" }
        if photos == 0 { return "\(videos) 个视频" }
        return "\(refs.count) 项"
    }
}

struct ChatHistoryHit: Identifiable, Hashable {
    let id: UUID
    var conversationID: UUID
    var conversationTitle: String
    var messageID: UUID
    var snippet: String
    var sentAt: Date
}
