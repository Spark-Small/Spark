//
//  CommunityAuthorCopy.swift
//  坐标系
//
//  作者资料 Sheet 文案。
//

import Foundation

enum CommunityAuthorCopy {
    static let hostedSection = "TA 发起的活动"
    static let recentPostsSection = "最近分享"
    static let recentPostsEmptyTitle = "还没有动态"
    static let recentPostsEmptyDescription = "对方在广场发布的分享会出现在这里。"
    static let report = "举报"
    static let block = "拉黑"
    static let cancel = "取消"
    static let authorProfileHint = "查看作者资料"
    /// 无搭子卡时的角色兜底（禁止 Sample 编造 bio/城市）。
    static let roleAuthor = "作者"
    static let roleHost = "活动发起人"
    static let roleUser = "用户"
    static let roleBuddy = "搭子"
    static let roleCompanion = "陪玩"

    static func reportTitle(_ name: String) -> String {
        "举报 \(name)"
    }

    static func blockConfirmTitle(_ name: String) -> String {
        "拉黑 \(name)？"
    }

    static let blockConfirmMessage = "拉黑后将不再收到对方的互动与消息。"
}
