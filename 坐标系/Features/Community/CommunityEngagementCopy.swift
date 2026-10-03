//
//  CommunityEngagementCopy.swift
//  坐标系
//
//  广场互动按钮 / a11y。
//

import Foundation

enum CommunityEngagementCopy {
    static let like = "赞"
    static let unlike = "取消赞"
    static let comment = "评论"
    static let share = "分享"
    static let bookmark = "收藏"
    static let unbookmark = "取消收藏"

    static func actionCountLabel(_ action: String, count: Int) -> String {
        "\(action)，\(Formatters.compactCount(count))"
    }

    static func postedAtAccessibility(_ relativeTime: String) -> String {
        "发布于\(relativeTime)"
    }
}
