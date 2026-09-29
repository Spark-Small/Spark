//
//  MessagingDeliveryPolicy.swift
//  坐标系
//
//  消息送达 / 自动回复边界（审核 2.3.1：不得伪造对方在线回复与已读）。
//  离线：HIG Feedback — 发送失败须可感知、可重试。
//

import Foundation

enum MessagingDeliveryPolicy {
    /// DEBUG 允许本地模拟对方自动回复。
    static var simulatesPeerAutoReply: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// DEBUG 允许 sleep 后把本地消息标为已读。
    static var simulatesLocalReadReceipt: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// DEBUG 发送后立刻标「已送达」；Release 仅「已发送」，等真实 IM 回执。
    static var upgradesLocalSendToDelivered: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }

    /// Release：无网时不得假装已发出（本地落盘也标失败，便于重试）。
    /// DEBUG 本地演示允许离线「已发送」。
    static var failsSendWhenOffline: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }

    static let pageSize = 80
}
