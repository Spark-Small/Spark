//
//  NotificationsCopy.swift
//  坐标系
//
//  站内通知中心文案。
//

import Foundation

enum NotificationsCopy {
    static let centerTitle = "通知"
    static let accessibilityEntry = "通知"
    static let accessibilityUnread = "有未读通知"
    static let markAllRead = "全部已读"
    static let clearAll = "清空通知"
    static let clearAllConfirmTitle = "清空全部通知？"
    static let clearAllConfirmMessage = "已读与未读都会从本机列表移除，系统通知中心不受影响。"
    static let settings = "通知设置"
    static let emptyTitle = "暂无通知"
    static let emptyDescription = "活动提醒、预约进度与消息会集中出现在这里。"
    static let filterAll = "全部"
    static let openSettingsHint = "管理推送类别与系统权限"
    static let swipeMarkRead = "标为已读"
    static let swipeDelete = "删除"
    static let sectionToday = "今天"
    static let sectionEarlier = "更早"
    static let moreActions = "更多操作"
    static let unreadA11y = "未读"

    static func unreadBadge(_ count: Int) -> String {
        count > 99 ? "99+" : "\(count)"
    }

    static func accessibilityEntry(unread: Int) -> String {
        unread > 0 ? "通知，\(unread) 条未读" : accessibilityEntry
    }
}
