//
//  ActivitiesBrowseSurface.swift
//  坐标系
//
//  活动发现表面：分类浏览 | 最近看过（非 ActivityCategory）。
//

import Foundation
import CoordinateModels

enum ActivitiesBrowseSurface: Hashable {
    case category(ActivityCategory)
    case recents

    var title: String {
        switch self {
        case .category(let category): category.title
        case .recents: ActivityBrowseCopy.recentsTitle
        }
    }

    var systemImage: String {
        switch self {
        case .category(let category): category.systemImage
        case .recents: "clock.arrow.circlepath"
        }
    }
}
