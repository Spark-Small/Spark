//
//  ActivityDetailWeatherPresentation.swift
//  坐标系
//
//  详情 Hero 天气：仅户外 / 城市探索展示「示意」氛围；其余类别只展示日期，
//  避免占位天气被当成决策条件（Apple HIG：不误导用户）。
//

import Foundation
import CoordinateModels

enum ActivityDetailWeatherPresentation {
    struct HeroChip: Equatable {
        let title: String
        let systemImage: String
        let accessibilityLabel: String
    }

    /// 头图信息条：日期为主；天气示意仅用于易受天气影响的品类。
    static func heroChip(for activity: Activity) -> HeroChip {
        let dateLine =
            "\(Formatters.monthDay.string(from: activity.date)) \(Formatters.weekday.string(from: activity.date))"

        guard showsWeatherCue(for: activity.category) else {
            return HeroChip(
                title: dateLine,
                systemImage: "calendar",
                accessibilityLabel: dateLine
            )
        }

        let seeded = LocalPlaceholderWeatherProvider.forecast(for: activity)
        let weatherLine = "天气示意 · \(seeded.conditionText)"
        return HeroChip(
            title: "\(dateLine) · \(weatherLine)",
            systemImage: seeded.systemImage,
            accessibilityLabel: "\(dateLine)，天气示意，\(seeded.conditionText)"
        )
    }

    private static func showsWeatherCue(for category: ActivityCategory) -> Bool {
        switch category {
        case .outdoorSports, .cityExplore:
            return true
        default:
            return false
        }
    }
}
