// Module: SparkBuddy — Maps activity categories to buddy browse filters.

import Foundation

public enum BuddyActivityCategoryBridge {
    public static func serviceFilter(forActivityCategory category: String) -> BuddyServiceFilter? {
        let normalized = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }

        switch normalized {
        case "户外", "outdoor", "hiking", "徒步", "运动", "sports":
            return .sports
        case "美食", "food", "饭搭子", "餐饮", "探店":
            return .food
        case "旅行", "travel", "tours", "citywalk", "城市漫游":
            return .cityWalk
        case "摄影", "photography", "拍照":
            return .photography
        case "夜生活", "nightlife", "酒吧", "livehouse":
            return .nightlife
        case "文化", "culture", "展览", "博物馆", "艺术":
            return .culture
        default:
            return nil
        }
    }
}
