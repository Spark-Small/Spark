//
//  Models.swift
//  坐标系
//
//  Created by NMD on 2026/7/15.
//

import Foundation
import SwiftUI

struct Activity: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var category: ActivityCategory
    var location: String
    var date: Date
    var capacity: Int
    var joined: Int
    var hostName: String
    var summary: String
    var fee: String
    var tags: [String]
    /// 距用户大致距离（km），示例数据；正式版可接定位
    var distanceKM: Double
    /// 发起时上传的本地封面文件名
    var localCoverName: String?
    /// 真实报名参与者；为空时详情页用种子展示兜底
    var participantNames: [String]
    var latitude: Double?
    var longitude: Double?
    /// 关联兴趣圈子（详情可进圈子群）
    var relatedCircleID: UUID?

    init(
        id: UUID,
        title: String,
        category: ActivityCategory,
        location: String,
        date: Date,
        capacity: Int,
        joined: Int,
        hostName: String,
        summary: String,
        fee: String,
        tags: [String],
        distanceKM: Double = 2.0,
        localCoverName: String? = nil,
        participantNames: [String] = [],
        latitude: Double? = nil,
        longitude: Double? = nil,
        relatedCircleID: UUID? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.location = location
        self.date = date
        self.capacity = capacity
        self.joined = joined
        self.hostName = hostName
        self.summary = summary
        self.fee = fee
        self.tags = tags
        self.distanceKM = distanceKM
        self.localCoverName = localCoverName
        self.participantNames = participantNames
        self.latitude = latitude
        self.longitude = longitude
        self.relatedCircleID = relatedCircleID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        category = try container.decode(ActivityCategory.self, forKey: .category)
        location = try container.decode(String.self, forKey: .location)
        date = try container.decode(Date.self, forKey: .date)
        capacity = try container.decode(Int.self, forKey: .capacity)
        joined = try container.decode(Int.self, forKey: .joined)
        hostName = try container.decode(String.self, forKey: .hostName)
        summary = try container.decode(String.self, forKey: .summary)
        fee = try container.decode(String.self, forKey: .fee)
        tags = try container.decode([String].self, forKey: .tags)
        distanceKM = try container.decodeIfPresent(Double.self, forKey: .distanceKM) ?? 2.0
        localCoverName = try container.decodeIfPresent(String.self, forKey: .localCoverName)
        participantNames = try container.decodeIfPresent([String].self, forKey: .participantNames) ?? []
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        relatedCircleID = try container.decodeIfPresent(UUID.self, forKey: .relatedCircleID)
    }

    var remainingSpots: Int { max(capacity - joined, 0) }
    var isAlmostFull: Bool { remainingSpots <= 3 && !isFull }
    var isFull: Bool { remainingSpots == 0 }

    var fillProgress: Double {
        guard capacity > 0 else { return 0 }
        return min(Double(joined) / Double(capacity), 1)
    }

    var isFree: Bool {
        fee.contains("免费") || fee.caseInsensitiveCompare("免费") == .orderedSame
    }

    /// 需走 App 内支付；店内 AA / 自费点单等只展示费用，不拉起支付
    var requiresInAppPayment: Bool {
        guard !isFree else { return false }
        let trimmed = fee.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !Self.isVenueSelfPayFee(trimmed)
    }

    /// 店内 AA / 自费点单 / 现场结算（不入 App 支付）
    static func isVenueSelfPayFee(_ fee: String) -> Bool {
        fee.contains("自费")
            || fee.contains("AA")
            || fee.contains("店内")
            || fee.contains("现场")
    }

    var isPast: Bool { date < .now }

    var hasAvailableSpots: Bool { !isFull }

    var isNearby: Bool { distanceKM <= RecommendationConfig.nearbyKM }

    /// 精确距离文案（假定已有实测或可展示的 km）
    var distanceText: String {
        if distanceKM < 1 {
            return String(format: "%.0f 米", distanceKM * 1000)
        }
        return String(format: "%.1f 公里", distanceKM)
    }

    /// 浏览卡用：无用户定位时不展示种子公里，改用行政区片段
    var districtLabel: String {
        let parts = location.split(separator: "·", maxSplits: 1, omittingEmptySubsequences: true)
        if let first = parts.first {
            return first.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return location
    }

    func distanceLabel(hasUserLocation: Bool) -> String {
        hasUserLocation ? distanceText : districtLabel
    }

    var coverSeed: Int { id.stableSeed }

    var coverPhoto: CommunityPhotoRef? {
        if let name = localCoverName,
           let url = CommunityPhotoStore.fileURL(named: name) {
            return .file(url)
        }
        if let asset = ActivityBundledCovers.assetName(for: id) {
            return .asset(asset)
        }
        return .seeded(seed: coverSeed, symbol: coverSymbol)
    }

    /// 封面 SF Symbol：按 seed 在类别内轮换，避免同品类同一图标
    var coverSymbol: String {
        category.coverSymbol(forSeed: coverSeed)
    }

    /// 展示用参与者：优先真实名单，种子数据兜底
    var displayParticipants: [String] {
        if !participantNames.isEmpty {
            return participantNames
        }
        let pool = ["阿凯", "Mia", "小周", "阿禾", "Leo", "林夏", "坐标系小队"]
        var names = [hostName]
        let extras = pool.filter { $0 != hostName }
        let need = max(joined - 1, 0)
        names.append(contentsOf: extras.prefix(need))
        return Array(names.prefix(max(joined, 1)))
    }
}

/// 全时段筛选：今天 / 明天 + 通用条件（服务各年龄、各日程）
enum ActivityQuickFilter: String, CaseIterable, Identifiable, Hashable {
    case today = "今天"
    case tomorrow = "明天"
    case nearby = "附近"
    case free = "免费"
    case available = "有空位"

    var id: String { rawValue }

    var isTimeFilter: Bool {
        self == .today || self == .tomorrow
    }

    var systemImage: String {
        switch self {
        case .today: "sun.max"
        case .tomorrow: "sunrise"
        case .nearby: "location"
        case .free: "gift"
        case .available: "person.badge.plus"
        }
    }
}

enum BuddyKind: String, CaseIterable, Identifiable {
    case free = "搭子"
    case paid = "陪玩"

    var id: String { rawValue }

    /// 顶栏分段与页面标题
    var stageTitle: String {
        switch self {
        case .free: "免费"
        case .paid: "预约"
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

struct InterestCircle: Identifiable, Hashable {
    let id: UUID
    var name: String
    var topic: String
    var city: String
    var memberCount: Int
    var weeklyActive: Int
    var tags: [String]
    var summary: String
    var isJoined: Bool
    var systemImage: String
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

struct CommunityPost: Identifiable, Hashable, Codable {
    let id: UUID
    var author: String
    var title: String
    var body: String
    var tags: [String]
    var likeCount: Int
    var commentCount: Int
    var repostCount: Int
    var shareCount: Int
    var postedAt: Date
    var isPinned: Bool
    /// 配图种子（本地 SeededSceneFill）
    var photoSeeds: [Int]
    var photoHue: Double
    /// 用户发布的本地图片文件名（Documents/CommunityPhotos）
    var localPhotoNames: [String]
    /// 关联活动名（详情内弱转化；优先用 relatedActivityID）
    var relatedActivityTitle: String?
    var relatedActivityID: UUID?
    var comments: [CommunityComment]
    /// 点赞者昵称（含当前用户）
    var likerNames: [String]
    /// 被举报次数（本地治理）
    var reportCount: Int
    /// 转发自原帖
    var repostedFromID: UUID?
    var quoteText: String?

    init(
        id: UUID,
        author: String,
        title: String,
        body: String,
        tags: [String],
        likeCount: Int,
        commentCount: Int,
        repostCount: Int,
        shareCount: Int,
        postedAt: Date,
        isPinned: Bool,
        photoSeeds: [Int],
        photoHue: Double,
        localPhotoNames: [String] = [],
        relatedActivityTitle: String? = nil,
        relatedActivityID: UUID? = nil,
        comments: [CommunityComment] = [],
        likerNames: [String] = [],
        reportCount: Int = 0,
        repostedFromID: UUID? = nil,
        quoteText: String? = nil
    ) {
        self.id = id
        self.author = author
        self.title = title
        self.body = body
        self.tags = tags
        self.likeCount = likeCount
        self.commentCount = commentCount
        self.repostCount = repostCount
        self.shareCount = shareCount
        self.postedAt = postedAt
        self.isPinned = isPinned
        self.photoSeeds = photoSeeds
        self.photoHue = photoHue
        self.localPhotoNames = localPhotoNames
        self.relatedActivityTitle = relatedActivityTitle
        self.relatedActivityID = relatedActivityID
        self.comments = comments
        self.likerNames = likerNames
        self.reportCount = reportCount
        self.repostedFromID = repostedFromID
        self.quoteText = quoteText
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        tags = try container.decode([String].self, forKey: .tags)
        likeCount = try container.decode(Int.self, forKey: .likeCount)
        commentCount = try container.decode(Int.self, forKey: .commentCount)
        repostCount = try container.decode(Int.self, forKey: .repostCount)
        shareCount = try container.decode(Int.self, forKey: .shareCount)
        postedAt = try container.decode(Date.self, forKey: .postedAt)
        isPinned = try container.decode(Bool.self, forKey: .isPinned)
        photoSeeds = try container.decode([Int].self, forKey: .photoSeeds)
        photoHue = try container.decode(Double.self, forKey: .photoHue)
        localPhotoNames = try container.decodeIfPresent([String].self, forKey: .localPhotoNames) ?? []
        relatedActivityTitle = try container.decodeIfPresent(String.self, forKey: .relatedActivityTitle)
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
        comments = try container.decodeIfPresent([CommunityComment].self, forKey: .comments) ?? []
        likerNames = try container.decodeIfPresent([String].self, forKey: .likerNames) ?? []
        reportCount = try container.decodeIfPresent(Int.self, forKey: .reportCount) ?? 0
        repostedFromID = try container.decodeIfPresent(UUID.self, forKey: .repostedFromID)
        quoteText = try container.decodeIfPresent(String.self, forKey: .quoteText)
    }

    var isRepost: Bool { repostedFromID != nil }

    /// 用户可见正文（引用转发优先展示 quote）。
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

struct CommunityComment: Identifiable, Hashable, Codable {
    let id: UUID
    var author: String
    var text: String
    var postedAt: Date
    /// 顶层评论为 nil；回复指向父评论
    var parentID: UUID?
    /// 回复对象昵称（展示「A ▶ B」）
    var replyToAuthor: String?
    var likeCount: Int
    /// 演示用地名，可空
    var region: String?
    /// 当前用户是否已赞（运行时；社区评论从 PlatformReviewsStore 读出时填充）
    var isLiked: Bool
    var dislikeCount: Int
    /// 当前用户是否已踩（运行时）
    var isDisliked: Bool

    init(
        id: UUID,
        author: String,
        text: String,
        postedAt: Date,
        parentID: UUID? = nil,
        replyToAuthor: String? = nil,
        likeCount: Int = 0,
        region: String? = nil,
        isLiked: Bool = false,
        dislikeCount: Int = 0,
        isDisliked: Bool = false
    ) {
        self.id = id
        self.author = author
        self.text = text
        self.postedAt = postedAt
        self.parentID = parentID
        self.replyToAuthor = replyToAuthor
        self.likeCount = likeCount
        self.region = region
        self.isLiked = isLiked
        self.dislikeCount = dislikeCount
        self.isDisliked = isDisliked
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        author = try container.decode(String.self, forKey: .author)
        text = try container.decode(String.self, forKey: .text)
        postedAt = try container.decode(Date.self, forKey: .postedAt)
        parentID = try container.decodeIfPresent(UUID.self, forKey: .parentID)
        replyToAuthor = try container.decodeIfPresent(String.self, forKey: .replyToAuthor)
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        region = try container.decodeIfPresent(String.self, forKey: .region)
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        dislikeCount = try container.decodeIfPresent(Int.self, forKey: .dislikeCount) ?? 0
        isDisliked = try container.decodeIfPresent(Bool.self, forKey: .isDisliked) ?? false
    }

    var isReply: Bool { parentID != nil }

    func isOwned(by currentUserName: String) -> Bool {
        author == currentUserName
    }
}

struct ChatConversation: Identifiable, Hashable, Codable {
    let id: UUID
    var title: String
    var subtitle: String
    var lastMessage: String
    var updatedAt: Date
    var unreadCount: Int
    var kind: ChatKind
    var isPinned: Bool
    var isMuted: Bool
    /// 活动群的举行时间；私聊 / 官方为空
    var eventAt: Date?
    /// 关联活动；旧会话可能为 nil，去重时 fallback 标题
    var relatedActivityID: UUID?
    /// 关联兴趣圈子（圈子群）
    var relatedCircleID: UUID?
    /// 收件箱预览是否来自自己（微信「我：」）
    var lastMessageIsMe: Bool
    /// 活动群群主（活动发起人昵称）
    var ownerName: String?
    /// 群成员昵称（本地演示）
    var memberNames: [String]
    /// 群公告
    var announcement: String?
    /// Ins 式消息请求（未接受前单独列表）
    var isMessageRequest: Bool
    /// 请求来源：好友申请 / 陌生人消息 / 群邀请
    var requestSource: MessageRequestSource?
    /// 请求列表预览文案（为空时回退 inboxPreview）
    var requestPreviewText: String?
    /// Ins Active now（本地演示）
    var peerIsActive: Bool
    /// 双向好友关系（接受申请 / UID 添加后为 true；临时会话为 false）
    var isFriend: Bool

    init(
        id: UUID,
        title: String,
        subtitle: String,
        lastMessage: String,
        updatedAt: Date,
        unreadCount: Int,
        kind: ChatKind,
        isPinned: Bool = false,
        isMuted: Bool = false,
        eventAt: Date? = nil,
        relatedActivityID: UUID? = nil,
        relatedCircleID: UUID? = nil,
        lastMessageIsMe: Bool = false,
        ownerName: String? = nil,
        memberNames: [String] = [],
        announcement: String? = nil,
        isMessageRequest: Bool = false,
        requestSource: MessageRequestSource? = nil,
        requestPreviewText: String? = nil,
        peerIsActive: Bool = false,
        isFriend: Bool = false
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.unreadCount = unreadCount
        self.kind = kind
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.eventAt = eventAt
        self.relatedActivityID = relatedActivityID
        self.relatedCircleID = relatedCircleID
        self.lastMessageIsMe = lastMessageIsMe
        self.ownerName = ownerName
        self.memberNames = memberNames
        self.announcement = announcement
        self.isMessageRequest = isMessageRequest
        self.requestSource = requestSource
        self.requestPreviewText = requestPreviewText
        self.peerIsActive = peerIsActive
        self.isFriend = isFriend
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subtitle = try container.decode(String.self, forKey: .subtitle)
        lastMessage = try container.decode(String.self, forKey: .lastMessage)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        unreadCount = try container.decode(Int.self, forKey: .unreadCount)
        kind = try container.decode(ChatKind.self, forKey: .kind)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isMuted = try container.decodeIfPresent(Bool.self, forKey: .isMuted) ?? false
        eventAt = try container.decodeIfPresent(Date.self, forKey: .eventAt)
        relatedActivityID = try container.decodeIfPresent(UUID.self, forKey: .relatedActivityID)
        relatedCircleID = try container.decodeIfPresent(UUID.self, forKey: .relatedCircleID)
        lastMessageIsMe = try container.decodeIfPresent(Bool.self, forKey: .lastMessageIsMe) ?? false
        ownerName = try container.decodeIfPresent(String.self, forKey: .ownerName)
        memberNames = try container.decodeIfPresent([String].self, forKey: .memberNames) ?? []
        announcement = try container.decodeIfPresent(String.self, forKey: .announcement)
        isMessageRequest = try container.decodeIfPresent(Bool.self, forKey: .isMessageRequest) ?? false
        requestSource = try container.decodeIfPresent(MessageRequestSource.self, forKey: .requestSource)
        requestPreviewText = try container.decodeIfPresent(String.self, forKey: .requestPreviewText)
        peerIsActive = try container.decodeIfPresent(Bool.self, forKey: .peerIsActive) ?? false
        if let decodedFriend = try container.decodeIfPresent(Bool.self, forKey: .isFriend) {
            isFriend = decodedFriend
        } else {
            isFriend = kind == .direct && !isMessageRequest && subtitle == "好友"
        }
    }

    var isGroup: Bool { kind == .activity || kind == .circle || kind == .group }

    var kindLabel: String {
        switch kind {
        case .activity, .group: "群聊"
        case .circle: "圈子"
        case .direct: "好友"
        case .notice: "通知"
        }
    }

    var systemImage: String {
        switch kind {
        case .activity: "person.crop.rectangle.stack.fill"
        case .circle, .group: "person.3.fill"
        case .direct: "message.fill"
        case .notice: "megaphone.fill"
        }
    }

    /// 仅两种社交会话：好友 1:1、活动群聊（通知为平台通道，非社交类型）
    var isFriendChat: Bool { kind == .direct }
    var isActivityGroup: Bool { kind == .activity }
    var isCircleGroup: Bool { kind == .circle }
    /// 选好友发起的多人会话
    var isPeerGroup: Bool { kind == .group }
    /// 消息列表中的群：活动群 + 圈子群 + 好友群
    var isSocialGroup: Bool { isActivityGroup || isCircleGroup || isPeerGroup }

    func isOwned(by userName: String) -> Bool {
        guard let ownerName, !ownerName.isEmpty else { return false }
        return ownerName.caseInsensitiveCompare(userName) == .orderedSame
    }

    /// 标题旁展示，样式与未读 `[3条]` 一致
    var eventTimeText: String? {
        guard kind == .activity, let eventAt else { return nil }
        return "[\(Formatters.activityEventTime(from: eventAt))]"
    }

    /// 收件箱一行预览（微信：自己消息加「我：」；系统提示原样）
    var inboxPreview: String {
        if lastMessageIsMe {
            if lastMessage.hasPrefix("我：") || lastMessage.hasPrefix("我:") {
                return lastMessage
            }
            return "我：\(lastMessage)"
        }
        return lastMessage
    }

    var requestPreview: String {
        if let requestPreviewText, !requestPreviewText.isEmpty {
            return requestPreviewText
        }
        return inboxPreview
    }
}

enum ChatKind: String, CaseIterable, Identifiable, Hashable, Codable {
    /// 活动群聊（一场局一个群）
    case activity = "活动群"
    /// 兴趣圈子群（加入圈子进入）
    case circle = "圈子群"
    /// 选多人发起的好友群
    case group = "群聊"
    /// 好友私聊（搭子 / 陪玩 / 主办等均落此类型，不做临时会话）
    case direct = "私聊"
    /// 平台通知（只读，非社交）
    case notice = "官方"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        switch raw {
        case Self.activity.rawValue: self = .activity
        case Self.circle.rawValue, "组织群": self = .circle
        case Self.group.rawValue: self = .group
        case Self.direct.rawValue: self = .direct
        case Self.notice.rawValue: self = .notice
        default:
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath, debugDescription: "Unknown ChatKind \(raw)")
            )
        }
    }
}

struct ChatMessage: Identifiable, Hashable, Codable {
    let id: UUID
    var sender: String
    var text: String
    var sentAt: Date
    var isMe: Bool
    var messageKind: ChatMessageKind
    /// Ins 式点心 / 表情回应
    var isLiked: Bool
    var reaction: String?
    /// 微信式引用回复
    var replyToSender: String?
    var replyToText: String?
    /// 微信式进群/退群等系统小字
    var isSystem: Bool
    var systemAudience: ChatSystemAudience
    /// 图片：CommunityPhotoStore 文件名
    var mediaLocalName: String?
    /// 语音秒数
    var voiceDuration: Double?
    /// 位置
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    /// 链接 / 社区分享卡
    var linkTitle: String?
    var linkSubtitle: String?
    var linkURLString: String?
    /// 活动卡
    var cardActivityID: UUID?
    /// 转账金额（演示）
    var transferAmount: Double?
    /// 转账实体 id（新链路；旧快照仍兼容 transferAmount）
    var transferID: UUID?
    /// 送达 / 已读（本地模拟）
    var deliveryStatus: ChatDeliveryStatus

    init(
        id: UUID,
        sender: String,
        text: String,
        sentAt: Date,
        isMe: Bool,
        messageKind: ChatMessageKind = .text,
        isLiked: Bool = false,
        reaction: String? = nil,
        replyToSender: String? = nil,
        replyToText: String? = nil,
        isSystem: Bool = false,
        systemAudience: ChatSystemAudience = .everyone,
        mediaLocalName: String? = nil,
        voiceDuration: Double? = nil,
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        linkTitle: String? = nil,
        linkSubtitle: String? = nil,
        linkURLString: String? = nil,
        cardActivityID: UUID? = nil,
        transferAmount: Double? = nil,
        transferID: UUID? = nil,
        deliveryStatus: ChatDeliveryStatus = .sent
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.sentAt = sentAt
        self.isMe = isMe
        self.messageKind = messageKind
        self.isLiked = isLiked
        self.reaction = reaction
        self.replyToSender = replyToSender
        self.replyToText = replyToText
        self.isSystem = isSystem
        self.systemAudience = systemAudience
        self.mediaLocalName = mediaLocalName
        self.voiceDuration = voiceDuration
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.linkTitle = linkTitle
        self.linkSubtitle = linkSubtitle
        self.linkURLString = linkURLString
        self.cardActivityID = cardActivityID
        self.transferAmount = transferAmount
        self.transferID = transferID
        self.deliveryStatus = deliveryStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        sender = try container.decode(String.self, forKey: .sender)
        text = try container.decode(String.self, forKey: .text)
        sentAt = try container.decode(Date.self, forKey: .sentAt)
        isMe = try container.decode(Bool.self, forKey: .isMe)
        messageKind = try container.decodeIfPresent(ChatMessageKind.self, forKey: .messageKind) ?? .text
        isLiked = try container.decodeIfPresent(Bool.self, forKey: .isLiked) ?? false
        reaction = try container.decodeIfPresent(String.self, forKey: .reaction)
        replyToSender = try container.decodeIfPresent(String.self, forKey: .replyToSender)
        replyToText = try container.decodeIfPresent(String.self, forKey: .replyToText)
        isSystem = try container.decodeIfPresent(Bool.self, forKey: .isSystem) ?? false
        systemAudience = try container.decodeIfPresent(ChatSystemAudience.self, forKey: .systemAudience) ?? .everyone
        mediaLocalName = try container.decodeIfPresent(String.self, forKey: .mediaLocalName)
        voiceDuration = try container.decodeIfPresent(Double.self, forKey: .voiceDuration)
        locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        linkTitle = try container.decodeIfPresent(String.self, forKey: .linkTitle)
        linkSubtitle = try container.decodeIfPresent(String.self, forKey: .linkSubtitle)
        linkURLString = try container.decodeIfPresent(String.self, forKey: .linkURLString)
        cardActivityID = try container.decodeIfPresent(UUID.self, forKey: .cardActivityID)
        transferAmount = try container.decodeIfPresent(Double.self, forKey: .transferAmount)
        transferID = try container.decodeIfPresent(UUID.self, forKey: .transferID)
        deliveryStatus = try container.decodeIfPresent(ChatDeliveryStatus.self, forKey: .deliveryStatus) ?? .sent
    }

    var previewText: String {
        if isSystem { return text }
        switch messageKind {
        case .text, .sticker: return text
        case .image: return "[图片]"
        case .voice: return "[语音]"
        case .location: return "[位置] \(locationName ?? "")"
        case .link: return "[链接] \(linkTitle ?? text)"
        case .activity: return "[活动] \(text)"
        case .transfer: return "[转账] ¥\(String(format: "%.2f", transferAmount ?? 0))"
        }
    }

    static func systemTip(
        _ text: String,
        audience: ChatSystemAudience = .everyone,
        at date: Date = .now
    ) -> ChatMessage {
        ChatMessage(
            id: UUID(),
            sender: "",
            text: text,
            sentAt: date,
            isMe: false,
            messageKind: .text,
            isSystem: true,
            systemAudience: audience
        )
    }
}

enum ChatMessageKind: String, Hashable, Codable, CaseIterable {
    case text
    case image
    case voice
    case location
    case link
    case activity
    case transfer
    case sticker
}

enum ChatDeliveryStatus: String, Hashable, Codable {
    case sent
    case delivered
    case read
}

enum ChatSystemAudience: String, Hashable, Codable {
    case everyone
    case hostOnly
}

enum MessageRequestSource: String, Hashable, Codable, CaseIterable {
    case friend = "好友申请"
    case directMessage = "陌生人消息"
    case groupInvite = "群聊邀请"
}

enum GroupMemberRole: String, Hashable, Codable, CaseIterable {
    case owner = "群主"
    case admin = "管理员"
    case member = "成员"

    var canManageMembers: Bool {
        self == .owner || self == .admin
    }
}

struct GroupMemberRecord: Identifiable, Hashable, Codable {
    var id: String { nickname.lowercased() }
    var nickname: String
    var role: GroupMemberRole
    var joinedAt: Date
    /// 本群昵称（与真实昵称不同时展示为 真实名（群昵称））
    var groupAlias: String?

    init(
        nickname: String,
        role: GroupMemberRole = .member,
        joinedAt: Date = .now,
        groupAlias: String? = nil
    ) {
        self.nickname = nickname
        self.role = role
        self.joinedAt = joinedAt
        self.groupAlias = groupAlias
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        nickname = try container.decode(String.self, forKey: .nickname)
        role = try container.decode(GroupMemberRole.self, forKey: .role)
        joinedAt = try container.decodeIfPresent(Date.self, forKey: .joinedAt) ?? .now
        groupAlias = try container.decodeIfPresent(String.self, forKey: .groupAlias)
    }
}

enum TransferStatus: String, Hashable, Codable, CaseIterable {
    case pending = "待收款"
    case accepted = "已收款"
    case expired = "已过期"
    case cancelled = "已取消"
    case refunded = "已退回"

    var isTerminal: Bool {
        switch self {
        case .pending: false
        case .accepted, .expired, .cancelled, .refunded: true
        }
    }
}

enum TransferLifecycle {
    /// 本地演示：待收款有效期（正式版由服务端 TTL 下发）
    static let pendingTTL: TimeInterval = 24 * 3600
}

struct TransferRecord: Identifiable, Hashable, Codable {
    let id: UUID
    var conversationID: UUID
    var amount: Double
    var senderName: String
    var recipientName: String
    var status: TransferStatus
    var createdAt: Date
    var updatedAt: Date?
    var messageID: UUID

    init(
        id: UUID = UUID(),
        conversationID: UUID,
        amount: Double,
        senderName: String,
        recipientName: String,
        status: TransferStatus = .pending,
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        messageID: UUID
    ) {
        self.id = id
        self.conversationID = conversationID
        self.amount = amount
        self.senderName = senderName
        self.recipientName = recipientName
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messageID = messageID
    }

    var expiresAt: Date {
        createdAt.addingTimeInterval(TransferLifecycle.pendingTTL)
    }

    var isPastExpiration: Bool {
        status == .pending && Date.now >= expiresAt
    }

    var pendingTimeRemaining: TimeInterval? {
        guard status == .pending else { return nil }
        return max(expiresAt.timeIntervalSinceNow, 0)
    }
}

enum CallSessionKind: String, Hashable, Codable, CaseIterable {
    case voice = "语音通话"
    case video = "视频通话"

    var systemImage: String {
        switch self {
        case .voice: "phone.fill"
        case .video: "video.fill"
        }
    }
}

enum CallSessionDirection: String, Hashable, Codable {
    case outgoing
    case incoming
}

enum CallSessionStatus: String, Hashable, Codable, CaseIterable {
    case ringing = "响铃中"
    case connecting = "连接中"
    case active = "通话中"
    case ended = "已结束"
    case missed = "未接听"
    case cancelled = "已取消"
    case rejected = "已拒绝"

    var isLive: Bool {
        self == .ringing || self == .connecting || self == .active
    }
}

struct CallSessionRecord: Identifiable, Hashable, Codable {
    let id: UUID
    var conversationID: UUID
    var kind: CallSessionKind
    var direction: CallSessionDirection
    var status: CallSessionStatus
    var startedAt: Date
    var connectedAt: Date?
    var endedAt: Date?

    init(
        id: UUID = UUID(),
        conversationID: UUID,
        kind: CallSessionKind,
        direction: CallSessionDirection = .outgoing,
        status: CallSessionStatus = .ringing,
        startedAt: Date = .now,
        connectedAt: Date? = nil,
        endedAt: Date? = nil
    ) {
        self.id = id
        self.conversationID = conversationID
        self.kind = kind
        self.direction = direction
        self.status = status
        self.startedAt = startedAt
        self.connectedAt = connectedAt
        self.endedAt = endedAt
    }

    var historyDetail: String {
        switch status {
        case .ended:
            if let connectedAt, let endedAt {
                let duration = max(Int(endedAt.timeIntervalSince(connectedAt)), 0)
                return "\(status.rawValue) · \(String(format: "%02d:%02d", duration / 60, duration % 60))"
            }
            return status.rawValue
        case .ringing, .connecting, .active, .missed, .cancelled, .rejected:
            return status.rawValue
        }
    }
}

/// Ins 式消息请求 / 好友申请
struct FriendRequest: Identifiable, Hashable, Codable {
    let id: UUID
    var fromName: String
    var message: String
    var createdAt: Date
    var status: FriendRequestStatus
}

enum FriendRequestStatus: String, Hashable, Codable {
    case pending
    case accepted
    case declined
}

/// 我方向他人发出的好友申请（等待对方通过）。
struct OutgoingFriendRequest: Identifiable, Hashable, Codable {
    let id: UUID
    var toName: String
    var message: String
    var createdAt: Date
    var status: FriendRequestStatus

    init(
        id: UUID = UUID(),
        toName: String,
        message: String,
        createdAt: Date = .now,
        status: FriendRequestStatus = .pending
    ) {
        self.id = id
        self.toName = toName
        self.message = message
        self.createdAt = createdAt
        self.status = status
    }
}

/// 聊天记录搜索命中
struct ChatHistoryHit: Identifiable, Hashable {
    let id: UUID
    var conversationID: UUID
    var conversationTitle: String
    var messageID: UUID
    var snippet: String
    var sentAt: Date
}

struct AppUser: Codable, Hashable, Identifiable {
    /// 本机稳定用户 UUID（游客与登录用户共用）
    var id: UUID
    var name: String
    var handle: String
    var city: String
    var bio: String
    var joinedCount: Int
    var hostedCount: Int
    var buddyCount: Int
    var interests: [String]
    /// 搭子页「也想找」快速状态
    var lookingFor: String
    /// Documents 下本地头像文件名
    var avatarLocalName: String? = nil
    /// 语音介绍时长（秒）；nil 表示未录制
    var voiceIntroDuration: Double? = nil
    /// 语音条副文案（可选）
    var voiceIntroCaption: String? = nil

    init(
        id: UUID = LocalUserIdentity.current,
        name: String,
        handle: String,
        city: String,
        bio: String,
        joinedCount: Int,
        hostedCount: Int,
        buddyCount: Int,
        interests: [String] = [],
        lookingFor: String = "",
        avatarLocalName: String? = nil,
        voiceIntroDuration: Double? = nil,
        voiceIntroCaption: String? = nil
    ) {
        self.id = id
        self.name = name
        self.handle = handle
        self.city = city
        self.bio = bio
        self.joinedCount = joinedCount
        self.hostedCount = hostedCount
        self.buddyCount = buddyCount
        self.interests = interests
        self.lookingFor = lookingFor
        self.avatarLocalName = avatarLocalName
        self.voiceIntroDuration = voiceIntroDuration
        self.voiceIntroCaption = voiceIntroCaption
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? LocalUserIdentity.current
        name = try container.decode(String.self, forKey: .name)
        handle = try container.decode(String.self, forKey: .handle)
        city = try container.decode(String.self, forKey: .city)
        bio = try container.decode(String.self, forKey: .bio)
        joinedCount = try container.decode(Int.self, forKey: .joinedCount)
        hostedCount = try container.decode(Int.self, forKey: .hostedCount)
        buddyCount = try container.decode(Int.self, forKey: .buddyCount)
        interests = try container.decodeIfPresent([String].self, forKey: .interests)
            ?? SampleData.currentUserInterests
        lookingFor = try container.decodeIfPresent(String.self, forKey: .lookingFor) ?? ""
        avatarLocalName = try container.decodeIfPresent(String.self, forKey: .avatarLocalName)
        voiceIntroDuration = try container.decodeIfPresent(Double.self, forKey: .voiceIntroDuration)
        voiceIntroCaption = try container.decodeIfPresent(String.self, forKey: .voiceIntroCaption)
    }
}
