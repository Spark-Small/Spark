//
//  ActivityNotificationFollowUp.swift
//  坐标系
//
//  活动通知点击后的后续动作（深链进行程并弹 Sheet）。
//

import Foundation

enum ActivityNotificationFollowUp: Equatable {
    case none
    /// 活动开始前提醒：进入行程页查看集合信息
    case openJourney
    case journeyFeedback
    case journeyRecap
}
