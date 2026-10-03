//
//  ActivityTaxonomy.swift
//  坐标系
//
//  活动一级分类 + 二级兴趣标签的唯一数据源。
//

import Foundation
import CoordinateModels

/// 兴趣选择数量约束（参考社交 / 活动类产品常见门槛）。
enum InterestSelectionLimits {
    /// 至少 3 项，保证推荐与搭子匹配有足够信号。
    static let minimum = 3
    /// 最多 8 项，避免全选导致画像稀释。
    static let maximum = 8

    static func meetsMinimum(_ count: Int) -> Bool { count >= minimum }
    static func canSelectMore(_ count: Int) -> Bool { count < maximum }
    static func isAtMaximum(_ count: Int) -> Bool { count >= maximum }

    /// 可见进度 / VoiceOver hint 共用；避免「已选」赘词。
    static func progressText(count: Int) -> String {
        let capped = max(0, count)
        if capped == 0 {
            return "请至少选择 \(minimum) 项"
        }
        if capped < minimum {
            return "\(capped)/\(maximum) · 再选 \(minimum - capped) 项即可开启"
        }
        if capped >= maximum {
            return "已满 \(maximum) 项，取消后再换也可以"
        }
        return "\(capped)/\(maximum)"
    }

    static let limitReachedFeedback = "最多选择 \(maximum) 项，取消一项后再换"
}

/// 一级分类下的二级兴趣 / 活动子类型目录。
enum ActivityTaxonomy {
    struct Group: Identifiable, Hashable, Sendable {
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

    /// 优先 `.fill` 变体，便于 `platformContentSymbolStyle()`（multicolor）出彩。
    static func systemImage(forSubtype subtype: String) -> String {
        switch subtype {
        case "徒步": "figure.hiking"
        case "爬山": "mountain.2.fill"
        case "骑行": "bicycle"
        case "跑步": "figure.run"
        case "野营": "tent.fill"
        case "飞盘": "circle.circle.fill"
        case "攀岩": "figure.climbing"
        case "桨板": "figure.open.water.swim"
        case "滑雪": "figure.skiing.downhill"
        case "羽毛球": "figure.badminton"
        case "篮球": "basketball.fill"
        case "足球": "figure.soccer"
        case "网球": "tennis.racket"
        case "乒乓球": "figure.table.tennis"
        case "咖啡交流": "cup.and.saucer.fill"
        case "下午茶": "mug.fill"
        case "语言交换": "bubble.left.and.bubble.right.fill"
        case "读书会": "book.fill"
        case "公园聊天": "leaf.fill"
        case "城市散步": "figure.walk"
        case "主题派对": "party.popper.fill"
        case "电影夜": "film.fill"
        case "聊天局": "ellipsis.bubble.fill"
        case "单身交友": "heart.fill"
        case "速配活动": "sparkles"
        case "情侣体验": "heart.circle.fill"
        case "探店": "storefront.fill"
        case "烹饪体验": "frying.pan.fill"
        case "火锅局": "flame.fill"
        case "烘焙": "birthday.cake.fill"
        case "品酒": "wineglass.fill"
        case "美食局": "fork.knife"
        case "桌游": "dice.fill"
        case "剧本杀": "theatermasks.fill"
        case "密室逃脱": "lock.shield.fill"
        case "KTV": "music.mic"
        case "电竞比赛": "desktopcomputer"
        case "Switch 聚会": "gamecontroller.fill"
        case "卡牌游戏": "rectangle.stack.fill"
        case "沉浸体验": "vision.pro"
        case "老城探索": "building.columns.fill"
        case "建筑摄影": "camera.fill"
        case "夜游": "moon.stars.fill"
        case "城市漫游": "map.fill"
        case "周边游": "binoculars.fill"
        case "一日游": "sun.max.fill"
        case "自驾": "car.fill"
        case "看展": "photo.on.rectangle.fill"
        case "陶艺": "circle.dashed"
        case "插花": "camera.macro"
        case "香薰": "aqi.medium"
        case "蜡烛": "flame.fill"
        case "手作 DIY": "hammer.fill"
        case "市集手作": "basket.fill"
        case "摄影交流": "camera.aperture"
        case "AI 分享": "cpu.fill"
        case "编程交流": "chevron.left.forwardslash.chevron.right"
        case "剪辑学习": "scissors"
        case "设计分享": "paintpalette.fill"
        case "创业交流": "briefcase.fill"
        case "行业沙龙": "person.3.fill"
        case "演讲分享": "mic.fill"
        default:
            category(forSubtype: subtype)?.systemImage ?? "tag.fill"
        }
    }
}
