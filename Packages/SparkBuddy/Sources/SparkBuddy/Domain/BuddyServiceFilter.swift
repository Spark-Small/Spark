// Module: SparkBuddy — Browse chip filter by service category.

import Foundation

public enum BuddyServiceFilter: String, CaseIterable, Identifiable, Sendable, Equatable {
    case all
    case cityWalk
    case food
    case photography
    case sports
    case nightlife
    case culture

    public var id: String { rawValue }

    public var localizedTitle: String {
        switch self {
        case .all:
            String(localized: "buddy.filter.all", defaultValue: "全部", comment: "All service filter")
        case .cityWalk:
            BuddyServiceCategory.cityWalk.localizedTitle
        case .food:
            BuddyServiceCategory.food.localizedTitle
        case .photography:
            BuddyServiceCategory.photography.localizedTitle
        case .sports:
            BuddyServiceCategory.sports.localizedTitle
        case .nightlife:
            BuddyServiceCategory.nightlife.localizedTitle
        case .culture:
            BuddyServiceCategory.culture.localizedTitle
        }
    }

    public var apiCategoryValue: String? {
        switch self {
        case .all:
            nil
        case .cityWalk:
            BuddyServiceCategory.cityWalk.apiValue
        case .food:
            BuddyServiceCategory.food.apiValue
        case .photography:
            BuddyServiceCategory.photography.apiValue
        case .sports:
            BuddyServiceCategory.sports.apiValue
        case .nightlife:
            BuddyServiceCategory.nightlife.apiValue
        case .culture:
            BuddyServiceCategory.culture.apiValue
        }
    }

    public var category: BuddyServiceCategory? {
        switch self {
        case .all: nil
        case .cityWalk: .cityWalk
        case .food: .food
        case .photography: .photography
        case .sports: .sports
        case .nightlife: .nightlife
        case .culture: .culture
        }
    }
}
