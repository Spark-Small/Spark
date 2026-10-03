//
//  PlatformReviewsCopy.swift
//  坐标系
//
//  统一评论 / 楼中楼文案（活动评价与广场共用）。
//

import Foundation

enum PlatformReviewsCopy {
    static let reply = "回复"
    static let delete = "删除"
    static let collapseReplies = "收起回复"
    static let needsEditTitle = "评论需要修改"
    static let needsEditDismiss = "知道了"
    static let ownerBadgeDefault = "作者"

    static func expandReplies(count: Int) -> String {
        count == 1 ? "展开 1 条回复" : "展开 \(count) 条回复"
    }

    static let expandCollapseHint = "展开或收起这条评论下的回复"

    static func replyPlaceholder(author: String) -> String {
        "回复 \(author)…"
    }
}
