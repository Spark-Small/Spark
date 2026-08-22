//
//  ActivityTaxonomy.swift
//  坐标系
//
//  活动一级分类 + 二级兴趣标签的唯一数据源。
//

import Foundation

/// 兴趣选择数量约束（参考社交 / 活动类产品常见门槛）。
enum InterestSelectionLimits {
    /// 至少 3 项，保证推荐与搭子匹配有足够信号。
    static let minimum = 3
    /// 最多 8 项，避免全选导致画像稀释。
    static let maximum = 8

    static func meetsMinimum(_ count: Int) -> Bool { count >= minimum }
    static func canSelectMore(_ count: Int) -> Bool { count < maximum }

    static func progressText(count: Int) -> String {
        if count == 0 {
            return "请至少选择 \(minimum) 项"
        }
        if count < minimum {
            return "已选 \(count)/\(maximum)，再选 \(minimum - count) 项即可开启"
        }
        if count >= maximum {
            return "已选满 \(maximum) 项，取消后再换也可以"
        }
        return "已选 \(count)/\(maximum)"
    }
}

/// 活动一级分类（筛选 / 发布）与完善资料页分组共用。
enum ActivityCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case all
    case forYou
    case outdoorSports
    case interestSocial
    case food
    case entertainment
    case cityExplore
    case handmade
    case learning

    var id: String { rawValue }

    /// 发现页标题菜单：「猜你喜欢」为首，不含「全部」。
    static var browseTitleCategories: [ActivityCategory] {
        [.forYou] + allCases.filter { $0 != .all && $0 != .forYou }
    }

    /// 发现页聚合浏览：不按一级分类过滤（「全部」「猜你喜欢」）。
    var isBrowseAggregate: Bool {
        self == .all || self == .forYou
    }

    var title: String {
        switch self {
        case .all: "全部"
        case .forYou: "猜你喜欢"
        case .outdoorSports: "运动户外"
        case .interestSocial: "兴趣社交"
        case .food: "美食活动"
        case .entertainment: "娱乐游戏"
        case .cityExplore: "城市探索"
        case .handmade: "手工体验"
        case .learning: "学习成长"
        }
    }

    /// 活动页筛选条：只展示一级分类前两字，节省横向空间。
    var shortTitle: String {
        String(title.prefix(2))
    }

    var systemImage: String {
        switch self {
        case .all: "square.grid.2x2"
        case .forYou: "sparkles"
        case .outdoorSports: "figure.hiking"
        case .interestSocial: "person.2"
        case .food: "fork.knife"
        case .entertainment: "gamecontroller"
        case .cityExplore: "building.2"
        case .handmade: "paintbrush.pointed"
        case .learning: "book"
        }
    }

    /// 封面用：同类轮换 2–3 个场景符号，避免列表「同一张壁纸」
    func coverSymbol(forSeed seed: Int) -> String {
        let options: [String]
        switch self {
        case .all:
            options = ["square.grid.2x2"]
        case .forYou:
            options = ["sparkles"]
        case .outdoorSports:
            options = ["figure.hiking", "figure.run", "bicycle", "figure.badminton", "tennis.racket"]
        case .interestSocial:
            options = ["person.2", "cup.and.saucer", "bubble.left.and.bubble.right"]
        case .food:
            options = ["fork.knife", "takeoutbag.and.cup.and.straw", "birthday.cake"]
        case .entertainment:
            options = ["gamecontroller", "dice", "music.note"]
        case .cityExplore:
            options = ["building.2", "camera", "map"]
        case .handmade:
            options = ["paintbrush.pointed", "scissors", "gift"]
        case .learning:
            options = ["book", "laptopcomputer", "lightbulb"]
        }
        return options[abs(seed) % options.count]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let value = ActivityCategory(rawValue: raw) {
            self = value
            return
        }
        // 旧版以中文 rawValue 落盘
        switch raw {
        case "全部": self = .all
        case "猜你喜欢": self = .forYou
        case "运动", "户外", "运动户外": self = .outdoorSports
        case "社交", "兴趣社交": self = .interestSocial
        case "美食", "美食活动": self = .food
        case "娱乐游戏": self = .entertainment
        case "文化", "城市探索": self = .cityExplore
        case "手工体验": self = .handmade
        case "学习成长": self = .learning
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown ActivityCategory: \(raw)"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// 一级分类下的二级兴趣 / 活动子类型目录。
enum ActivityTaxonomy {
    struct Group: Identifiable, Hashable {
        var id: ActivityCategory { category }
        let category: ActivityCategory
        let subtypes: [String]
    }

    static let groups: [Group] = [
        Group(category: .outdoorSports, subtypes: [
            "徒步", "爬山", "骑行", "跑步", "野营", "飞盘", "攀岩", "桨板", "滑雪",
            "羽毛球", "篮球", "足球", "网球", "乒乓球"
        ]),
        Group(category: .interestSocial, subtypes: [
            "咖啡交流", "下午茶", "语言交换", "读书会", "公园聊天", "城市散步",
            "主题派对", "电影夜", "聊天局", "单身交友", "速配活动", "情侣体验"
        ]),
        Group(category: .food, subtypes: [
            "探店", "烹饪体验", "火锅局", "烘焙", "品酒", "美食局"
        ]),
        Group(category: .entertainment, subtypes: [
            "桌游", "剧本杀", "密室逃脱", "KTV", "电竞比赛", "Switch 聚会", "卡牌游戏", "沉浸体验"
        ]),
        Group(category: .cityExplore, subtypes: [
            "老城探索", "建筑摄影", "夜游", "城市漫游", "周边游", "一日游", "自驾", "看展"
        ]),
        Group(category: .handmade, subtypes: [
            "陶艺", "插花", "香薰", "蜡烛", "手作 DIY", "市集手作"
        ]),
        Group(category: .learning, subtypes: [
            "摄影交流", "AI 分享", "编程交流", "剪辑学习", "设计分享", "创业交流", "行业沙龙", "演讲分享"
        ])
    ]

    static var primaryCategories: [ActivityCategory] {
        groups.map(\.category)
    }

    static var allSubtypes: [String] {
        groups.flatMap(\.subtypes)
    }

    static func category(forSubtype subtype: String) -> ActivityCategory? {
        groups.first { $0.subtypes.contains(subtype) }?.category
    }

    static func subtypes(for category: ActivityCategory) -> [String] {
        groups.first { $0.category == category }?.subtypes ?? []
    }

    static func systemImage(forSubtype subtype: String) -> String {
        switch subtype {
        case "徒步": "figure.hiking"
        case "爬山": "mountain.2"
        case "骑行": "bicycle"
        case "跑步": "figure.run"
        case "野营": "tent"
        case "飞盘": "circle.circle"
        case "攀岩": "figure.climbing"
        case "桨板": "figure.open.water.swim"
        case "滑雪": "figure.skiing.downhill"
        case "羽毛球": "figure.badminton"
        case "篮球": "basketball"
        case "足球": "soccerball"
        case "网球": "tennis.racket"
        case "乒乓球": "figure.table.tennis"
        case "咖啡交流": "cup.and.saucer"
        case "下午茶": "mug"
        case "语言交换": "bubble.left.and.bubble.right"
        case "读书会": "book"
        case "公园聊天": "leaf"
        case "城市散步": "figure.walk"
        case "主题派对": "party.popper"
        case "电影夜": "film"
        case "聊天局": "ellipsis.bubble"
        case "单身交友": "heart"
        case "速配活动": "sparkles"
        case "情侣体验": "heart.circle"
        case "探店": "storefront"
        case "烹饪体验": "frying.pan"
        case "火锅局": "flame"
        case "烘焙": "birthday.cake"
        case "品酒": "wineglass"
        case "美食局": "fork.knife"
        case "桌游": "dice"
        case "剧本杀": "theatermasks"
        case "密室逃脱": "lock.shield"
        case "KTV": "music.mic"
        case "电竞比赛": "desktopcomputer"
        case "Switch 聚会": "gamecontroller"
        case "卡牌游戏": "rectangle.stack"
        case "沉浸体验": "vision.pro"
        case "老城探索": "building.columns"
        case "建筑摄影": "camera"
        case "夜游": "moon.stars"
        case "城市漫游": "map"
        case "周边游": "binoculars"
        case "一日游": "sun.max"
        case "自驾": "car"
        case "看展": "photo.on.rectangle"
        case "陶艺": "circle.dashed"
        case "插花": "camera.macro"
        case "香薰": "aqi.medium"
        case "蜡烛": "candle"
        case "手作 DIY": "hammer"
        case "市集手作": "basket"
        case "摄影交流": "camera.aperture"
        case "AI 分享": "cpu"
        case "编程交流": "chevron.left.forwardslash.chevron.right"
        case "剪辑学习": "scissors"
        case "设计分享": "paintpalette"
        case "创业交流": "briefcase"
        case "行业沙龙": "person.3"
        case "演讲分享": "mic"
        default:
            category(forSubtype: subtype)?.systemImage ?? "tag"
        }
    }
}
