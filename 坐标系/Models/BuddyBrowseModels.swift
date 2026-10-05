//
//  BuddyBrowseModels.swift
//  坐标系
//
//  搭子发现筛选、资料与同好卡。
//

import Foundation
import SwiftUI
import CoordinateModels

enum BuddyKind: String, CaseIterable, Identifiable {
    case free = "搭子"
    case paid = "陪玩"
    case clubs = "俱乐部"

    var id: String { rawValue }

    /// 顶栏分段与页面标题
    var stageTitle: String {
        switch self {
        case .free: "找搭子"
        case .paid: "约陪玩"
        case .clubs: "俱乐部"
        }
    }

    var systemImage: String {
        switch self {
        case .free: "person.2"
        case .paid: "chineseyuanrenminbisign"
        case .clubs: "person.3"
        }
    }

    /// 三模式均有浏览筛选；条件集按 `kind` 分流（人设 / 服务 / 主题）。
    var usesBrowseFilters: Bool { true }

    /// - Warning: 历史别名；请用 `usesBrowseFilters`。
    var usesPeopleFilters: Bool { usesBrowseFilters }
}

struct BuddyFilter: Equatable {
    /// 搭子页默认免费找人；`.paid` 为花钱预约；`.clubs` 为俱乐部
    var kind: BuddyKind = .free
    var gender: BuddyGender?
    var maxDistanceKM: Double = 20
    var hobby: String?
    /// 「我想怎么玩」意图筛（找搭子）；空 = 不限
    var intents: Set<ProfileIntent> = []
    /// 开放域意图词（MatchScorer / 排序加权）；发现页暂无搜索 UI，勿当顶栏筛选条件。
    var query: String = ""
    /// 预约服务类型；`nil` = 全部（仅约陪玩）
    var serviceType: CompanionServiceType?
    var availableOnly = false
    /// 俱乐部主题；`nil` = 全部（仅俱乐部）
    var clubTopic: String?

    /// 当前模式下发现条件是否为默认（不含模式切换本身）。
    var isDefault: Bool {
        let queryEmpty = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch kind {
        case .free:
            return gender == nil
                && maxDistanceKM >= 20
                && hobby == nil
                && intents.isEmpty
                && queryEmpty
        case .paid:
            return gender == nil
                && maxDistanceKM >= 20
                && serviceType == nil
                && !availableOnly
                && queryEmpty
        case .clubs:
            return clubTopic == nil && queryEmpty
        }
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
    /// 稳定用户身份；匹配优先于昵称。旧数据 / 占位卡可缺省。
    var userID: UUID? = nil
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
    /// 「我想怎么玩」；空则卡面回落 lookingFor
    var intents: [ProfileIntent] = []
    var prompts: [ProfilePrompt] = []
    var occupation: ProfileOccupation? = nil
    var meetRadius: ProfileMeetRadius? = nil
    var mbti: ProfileMBTI? = nil
    var zodiac: ProfileZodiac? = nil
    /// 生活墙本机文件名（本人投影 / 本机可见）
    var galleryLocalNames: [String] = []
    /// 生活墙远程 HTTPS（发现目录 / 远程资料下发）
    var galleryRemoteURLs: [URL] = []
    /// 对外语音介绍时长（秒）；nil 表示未录制。展示在搭子 / 陪玩资料页。
    var voiceIntroDuration: Double? = nil
    /// 语音条说明（可选）
    var voiceIntroCaption: String? = nil

    var heightText: String { "\(heightCM)cm" }
    var weightText: String { "\(weightKG)kg" }

    var intentDisplayLine: String {
        ProfileIntentLimits.displayLine(intents: intents, legacyLookingFor: lookingFor)
    }

    /// 资料详情生活墙：远程 URL > 本机文件名 > 发现卡 photoRefs。
    var lifeGalleryRefs: [CommunityPhotoRef] {
        if !galleryRemoteURLs.isEmpty {
            return galleryRemoteURLs.map(CommunityPhotoRef.remote)
        }
        let localRefs = galleryLocalNames.compactMap { name -> CommunityPhotoRef? in
            if let url = LocalMediaLibrary.fileURL(named: name) {
                return .file(url)
            }
            if UIImage(named: name) != nil {
                return .asset(name)
            }
            return nil
        }
        if !localRefs.isEmpty { return localRefs }
        return photoRefs
    }

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

