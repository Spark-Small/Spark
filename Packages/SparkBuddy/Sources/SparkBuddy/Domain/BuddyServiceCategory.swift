// Module: SparkBuddy — Companion service vertical (city walk, food, photo, etc.).

import Foundation

/// Primary service category for browse filters and listing cards.
public enum BuddyServiceCategory: String, Sendable, Equatable, Codable, CaseIterable {
    case cityWalk
    case food
    case photography
    case sports
    case nightlife
    case culture

    public var localizedTitle: String {
        switch self {
        case .cityWalk:
            String(localized: "buddy.category.cityWalk", defaultValue: "城市漫游", comment: "City walk buddy")
        case .food:
            String(localized: "buddy.category.food", defaultValue: "美食探索", comment: "Food buddy")
        case .photography:
            String(localized: "buddy.category.photography", defaultValue: "摄影陪拍", comment: "Photo buddy")
        case .sports:
            String(localized: "buddy.category.sports", defaultValue: "运动搭子", comment: "Sports buddy")
        case .nightlife:
            String(localized: "buddy.category.nightlife", defaultValue: "夜生活", comment: "Nightlife buddy")
        case .culture:
            String(localized: "buddy.category.culture", defaultValue: "文化体验", comment: "Culture buddy")
        }
    }

    public var systemImage: String {
        switch self {
        case .cityWalk: "figure.walk"
        case .food: "fork.knife"
        case .photography: "camera.fill"
        case .sports: "figure.run"
        case .nightlife: "moon.stars.fill"
        case .culture: "building.columns.fill"
        }
    }

    public var apiValue: String {
        switch self {
        case .cityWalk: "city_walk"
        case .food: "food"
        case .photography: "photography"
        case .sports: "sports"
        case .nightlife: "nightlife"
        case .culture: "culture"
        }
    }

    public init?(apiValue: String) {
        switch apiValue {
        case "city_walk": self = .cityWalk
        case "food": self = .food
        case "photography": self = .photography
        case "sports": self = .sports
        case "nightlife": self = .nightlife
        case "culture": self = .culture
        default: return nil
        }
    }
}
