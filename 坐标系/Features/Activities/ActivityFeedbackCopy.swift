//
//  ActivityFeedbackCopy.swift
//  坐标系
//
//  活动域瞬态反馈文案（haptic + VoiceOver announce 的唯一字符串源）。
//

import Foundation
import CoordinateModels

enum ActivityFeedbackCopy {
    static let favorited = "已收藏活动"
    static let unfavorited = "已取消收藏"
    static let unjoined = "已取消参加"
    static let waitlistUnnecessary = "当前无需候补"
    static let waitlistLeft = "已退出候补"
    static let waitlistJoined = "已加入候补，有空位时会提醒你"
    static let waitlistPromoted = "已转正参加"
    static let waitlistPaymentRequired = "请先支付后再转正参加"
    static let joinFailed = "暂时无法完成报名，请稍后重试"
    static let activityUnavailable = "活动不可用或已下架"
    static let feedbackThanks = "感谢你的反馈"
    static let recapPublished = "复盘已发布"

    static func waitlistSpotOpened(title: String) -> String {
        "「\(title)」有空位了，可转正参加"
    }
    static let activityUpdated = "活动已更新"
    static let activityCancelled = "活动已取消"
    static let scheduleNeedsFuture = "请选择未来的开始时间"
    static let scheduleUpdated = "活动时间已更新"

    static func capacityUpdated(to count: Int) -> String {
        "名额已更新为 \(count) 人"
    }
}
