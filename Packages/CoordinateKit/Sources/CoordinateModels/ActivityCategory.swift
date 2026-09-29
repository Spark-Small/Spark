import Foundation

public enum ActivityCategory: String, CaseIterable, Identifiable, Hashable, Codable, Sendable {
    case all
    case forYou
    case outdoorSports
    case interestSocial
    case food
    case entertainment
    case cityExplore
    case handmade
    case learning

    public var id: String { rawValue }

    /// 发现页标题菜单：「猜你喜欢」为首，不含「全部」。
    public static var browseTitleCategories: [ActivityCategory] {
        [.forYou] + allCases.filter { $0 != .all && $0 != .forYou }
    }

    /// 发现页聚合浏览：不按一级分类过滤（「全部」「猜你喜欢」）。
    public var isBrowseAggregate: Bool {
        self == .all || self == .forYou
    }

    public var title: String {
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
    public var shortTitle: String {
        String(title.prefix(2))
    }

    public var systemImage: String {
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
    public func coverSymbol(forSeed seed: Int) -> String {
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

    public init(from decoder: Decoder) throws {
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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}