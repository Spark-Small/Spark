// Module: SparkActivity — One-tap presets for casual meetup creation.

import Foundation

/// Quick-start templates aligned with inbox / detail display fields (title · category · schedule · capacity).
public enum ActivityCreateQuickTemplate: String, CaseIterable, Sendable, Identifiable {
    case coffee
    case meal
    case outdoor
    case sports
    case boardGame
    case study
    case photoWalk
    case nightSnack

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .coffee:
            String(localized: "activity.create.template.coffee", defaultValue: "咖啡小局", comment: "Coffee template")
        case .meal:
            String(localized: "activity.create.template.meal", defaultValue: "饭搭子", comment: "Meal template")
        case .outdoor:
            String(localized: "activity.create.template.outdoor", defaultValue: "户外走走", comment: "Outdoor template")
        case .sports:
            String(localized: "activity.create.template.sports", defaultValue: "运动打卡", comment: "Sports template")
        case .boardGame:
            String(localized: "activity.create.template.boardGame", defaultValue: "桌游局", comment: "Board game template")
        case .study:
            String(localized: "activity.create.template.study", defaultValue: "自习局", comment: "Study template")
        case .photoWalk:
            String(localized: "activity.create.template.photoWalk", defaultValue: "摄影散步", comment: "Photo walk template")
        case .nightSnack:
            String(localized: "activity.create.template.nightSnack", defaultValue: "夜宵小聚", comment: "Night snack template")
        }
    }

    public var systemImage: String {
        switch self {
        case .coffee: "cup.and.saucer.fill"
        case .meal: "fork.knife"
        case .outdoor: "figure.hiking"
        case .sports: "figure.run"
        case .boardGame: "dice.fill"
        case .study: "book.fill"
        case .photoWalk: "camera.fill"
        case .nightSnack: "moon.stars.fill"
        }
    }

    /// Fills title, category, capacity, time, and a short description hint when empty.
    public func apply(to draft: inout CreateActivityDraft) {
        draft.title = defaultTitle
        draft.category = defaultCategory
        draft.capacity = defaultCapacity
        draft.startsAt = Self.suggestedStartDate(for: self)
        if draft.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draft.description = suggestedDescription
        }
    }

    private var defaultTitle: String {
        switch self {
        case .coffee:
            String(localized: "activity.create.template.coffee.title", defaultValue: "咖啡小局", comment: "Coffee title")
        case .meal:
            String(localized: "activity.create.template.meal.title", defaultValue: "饭搭子局", comment: "Meal title")
        case .outdoor:
            String(localized: "activity.create.template.outdoor.title", defaultValue: "户外走走", comment: "Outdoor title")
        case .sports:
            String(localized: "activity.create.template.sports.title", defaultValue: "运动打卡局", comment: "Sports title")
        case .boardGame:
            String(localized: "activity.create.template.boardGame.title", defaultValue: "桌游小局", comment: "Board game title")
        case .study:
            String(localized: "activity.create.template.study.title", defaultValue: "自习搭子局", comment: "Study title")
        case .photoWalk:
            String(localized: "activity.create.template.photoWalk.title", defaultValue: "摄影散步局", comment: "Photo walk title")
        case .nightSnack:
            String(localized: "activity.create.template.nightSnack.title", defaultValue: "夜宵小聚", comment: "Night snack title")
        }
    }

    private var defaultCategory: String {
        switch self {
        case .coffee:
            String(localized: "activity.create.template.coffee.category", defaultValue: "咖啡", comment: "Coffee category")
        case .meal:
            String(localized: "activity.create.template.meal.category", defaultValue: "聚餐", comment: "Meal category")
        case .outdoor:
            String(localized: "activity.create.template.outdoor.category", defaultValue: "户外", comment: "Outdoor category")
        case .sports:
            String(localized: "activity.create.template.sports.category", defaultValue: "运动", comment: "Sports category")
        case .boardGame:
            String(localized: "activity.create.template.boardGame.category", defaultValue: "桌游", comment: "Board game category")
        case .study:
            String(localized: "activity.create.template.study.category", defaultValue: "自习", comment: "Study category")
        case .photoWalk:
            String(localized: "activity.create.template.photoWalk.category", defaultValue: "摄影", comment: "Photo category")
        case .nightSnack:
            String(localized: "activity.create.template.nightSnack.category", defaultValue: "夜宵", comment: "Night snack category")
        }
    }

    private var suggestedDescription: String {
        switch self {
        case .coffee:
            String(
                localized: "activity.create.template.coffee.description",
                defaultValue: "轻松见面聊聊，选个方便的咖啡馆。",
                comment: "Coffee description hint"
            )
        case .meal:
            String(
                localized: "activity.create.template.meal.description",
                defaultValue: "一起吃顿饭，费用现场 AA。",
                comment: "Meal description hint"
            )
        case .outdoor:
            String(
                localized: "activity.create.template.outdoor.description",
                defaultValue: "轻松走走，强度适中，穿舒适鞋。",
                comment: "Outdoor description hint"
            )
        case .sports:
            String(
                localized: "activity.create.template.sports.description",
                defaultValue: "一起出汗打卡，水平不限。",
                comment: "Sports description hint"
            )
        case .boardGame:
            String(
                localized: "activity.create.template.boardGame.description",
                defaultValue: "带上一款桌游或现场选游戏。",
                comment: "Board game description hint"
            )
        case .study:
            String(
                localized: "activity.create.template.study.description",
                defaultValue: "安静自习，互相监督不玩手机。",
                comment: "Study description hint"
            )
        case .photoWalk:
            String(
                localized: "activity.create.template.photoWalk.description",
                defaultValue: "边走边拍，分享机位和路线。",
                comment: "Photo walk description hint"
            )
        case .nightSnack:
            String(
                localized: "activity.create.template.nightSnack.description",
                defaultValue: "夜宵小聚，地点好找、随时可散。",
                comment: "Night snack description hint"
            )
        }
    }

    private var defaultCapacity: Int {
        switch self {
        case .coffee, .study: CreateActivityDraft.smallGroupCapacityPresets[0]
        case .meal, .outdoor, .sports, .photoWalk, .nightSnack: CreateActivityDraft.defaultCapacity
        case .boardGame: CreateActivityDraft.smallGroupCapacityPresets[2]
        }
    }

    private static func suggestedStartDate(for template: ActivityCreateQuickTemplate) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date().addingTimeInterval(86_400)
        var components = calendar.dateComponents([.year, .month, .day], from: tomorrow)
        switch template {
        case .coffee, .meal, .boardGame, .nightSnack:
            components.hour = 19
            components.minute = 0
        case .outdoor, .sports, .photoWalk:
            components.hour = 9
            components.minute = 30
        case .study:
            components.hour = 14
            components.minute = 0
        }
        return calendar.date(from: components) ?? tomorrow
    }
}
