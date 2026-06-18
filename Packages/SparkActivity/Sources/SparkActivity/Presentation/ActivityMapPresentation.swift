// Module: SparkActivity — Copy variants for discover vs itinerary maps.

import Foundation

enum ActivityMapPresentation: Sendable, Equatable {
    case discover
    case itinerary

    var emptyTitle: String {
        switch self {
        case .discover:
            String(
                localized: "activity.discoverMap.empty.title",
                defaultValue: "附近暂无公开活动",
                comment: "Discover map empty"
            )
        case .itinerary:
            String(
                localized: "activity.itineraryMap.empty.title",
                defaultValue: "暂无可显示的行程地点",
                comment: "Itinerary map empty"
            )
        }
    }

    var emptySubtitle: String {
        switch self {
        case .discover:
            String(
                localized: "activity.discoverMap.empty.subtitle",
                defaultValue: "换个分类或时间试试，或稍后再来看。",
                comment: "Discover map empty hint"
            )
        case .itinerary:
            String(
                localized: "activity.itineraryMap.empty.subtitle",
                defaultValue: "报名活动并填写地点后，会显示在行程地图上。",
                comment: "Itinerary map empty hint"
            )
        }
    }

    var navigationTitle: String {
        switch self {
        case .discover:
            String(
                localized: "activity.discover.mode.map",
                defaultValue: "活动地图",
                comment: "Discover public activity map"
            )
        case .itinerary:
            String(
                localized: "activity.itineraryMap.title",
                defaultValue: "我的行程地图",
                comment: "Personal itinerary map"
            )
        }
    }
}
