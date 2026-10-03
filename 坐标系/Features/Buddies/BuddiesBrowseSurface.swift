//
//  BuddiesBrowseSurface.swift
//  坐标系
//
//  搭子发现表面：模式浏览 | 最近浏览（非 BuddyKind）。
//

import Foundation

enum BuddiesBrowseSurface: Hashable {
    case kind(BuddyKind)
    case recents

    var title: String {
        switch self {
        case .kind(let kind): kind.stageTitle
        case .recents: BuddyBrowseCopy.recentsTitle
        }
    }

    var systemImage: String {
        switch self {
        case .kind(let kind): kind.systemImage
        case .recents: "clock.arrow.circlepath"
        }
    }
}
