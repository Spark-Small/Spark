//
//  PlatformReviewsCopy.swift
//  坐标系
//
//  统一评论 / 楼中楼文案（活动评价与广场共用）。
//

import Foundation

enum PlatformReviewsCopy {
    static let reply = "回复"
    static let send = "发送"
    static let writeCancel = "取消"
    static let writeReviewTitle = "写评价"
    static let writeReplyTitle = "写回复"
    static let identitySection = "展示身份"
    static let identityNamed = "实名"
    static let identityAnonymous = "匿名"
    static let identityFooter = "匿名评价在口碑区显示为「匿名用户」，平台仍保留订单关联以防刷评。"
    static let ratingSection = "评分"
    static let anonymousAuthor = "匿名用户"
    static let alreadyReviewed = "该订单已评价"
    static let needCompletedOrder = "需完成预约后才能评价"
    static let cancelReply = "取消回复"
    static let delete = "删除"
    static let collapseReplies = "收起回复"

    static func replyingTo(_ author: String) -> String {
        "正在回复 \(author)"
    }
    static let needsEditTitle = "评论需要修改"
    static let needsEditDismiss = "知道了"
    static let ownerBadgeDefault = "作者"
    static let ownerBadgeCompanion = "陪玩"

    static func expandReplies(count: Int) -> String {
        count == 1 ? "展开 1 条回复" : "展开 \(count) 条回复"
    }

    static let expandCollapseHint = "展开或收起这条评论下的回复"

    static func replyPlaceholder(author: String) -> String {
        "回复 \(author)…"
    }

    static let voicePlaceholder = "[语音]"
    static let voiceSaveFailed = "语音保存失败，请重试。"
}
