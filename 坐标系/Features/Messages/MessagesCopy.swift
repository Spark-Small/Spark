//
//  MessagesCopy.swift
//  坐标系
//
//  消息模块文案入口：收件箱 / 筛选 / 空态 / 发起聊天 / 通用 chrome。
//  好友 → MessagesCopy+Friend；会话 → +Conversation；附件社交 → +AttachSocial。
//

import CoordinateModels
import Foundation

/// Pure string constants — opt out of default MainActor isolation so values can be
/// used as default parameter expressions (which are evaluated in a nonisolated context).
nonisolated enum MessagesCopy {
    // MARK: - Inbox / filters

    static let searchPrompt = "搜索好友、群聊和聊天记录"
    static let rootTitle = "消息"
    static let searchSectionConversations = "好友与群聊"
    static let searchSectionHistory = "聊天记录"
    static let filterGroups = "群聊"
    static let filterAll = "全部"
    static let filterUnread = "未读"
    static let filterMenuTitle = "筛选会话"
    static let filterMenuTitleActive = "筛选已启用"
    static let filterMenuHint = "筛选会话，或打开陌生人信箱"
    static func filterMenuValue(_ title: String, count: Int) -> String {
        count > 0 ? "\(title)，\(count) 个会话" : title
    }
    static func strangerMailboxBadgeA11y(_ count: Int) -> String {
        "陌生人信箱 \(count) 个"
    }
    static let contactsPlusMenuHint = "添加好友或查看好友请求"
    static let filterEmptyTitle = "这个筛选下还没有会话"
    static let filterEmptyDescription = "换个筛选看看，或去发现活动、找搭子"
    static let filterEmptyShowAll = "看全部"
    static let blockedOnlyEmptyTitle = "暂无可见会话"
    static let blockedOnlyEmptyDescription = "屏蔽联系人后，相关私聊不会出现在收件箱。可发起新聊天，或去活动、搭子认识新伙伴。"
    static let activityGroupBadge = "活动群"
    static let circleGroupBadge = "俱乐部"
    static func activityGroupWelcome(title: String) -> String {
        "这是「\(title)」的活动群，集合信息会发在这里"
    }
    static func activityGroupSubtitleLine(eventAt: Date?) -> String {
        guard let eventAt else { return activityGroupBadge }
        return "\(activityGroupBadge) · \(Formatters.activityEventTime(from: eventAt))"
    }
    static func circleGroupSubtitleLine(memberCount: Int) -> String {
        "\(circleGroupBadge) · \(memberCount) 位成员"
    }
    static let friendsListTitle = "通讯录"
    static let friendsListHint = "查看好友与好友请求"
    static let friendsListEmptyTitle = "通讯录为空"
    static let friendsListEmptyDescription = "邀请好友一起玩，或通过 UID 添加联系人"
    static let friendsListSearch = "搜索通讯录"
    static let friendsListChat = "发消息"
    static let inviteFriends = "邀请好友"
    static let inviteFriendsShareText = "来坐标系一起玩活动、找搭子！"

    static let emptyInboxTitle = "还没有会话"
    static let emptyInboxDescription = "参加活动会自动创建活动群；加入俱乐部或去搭子页打招呼，会话会出现在这里"
    static let emptyInboxBrowseActivities = "去发现活动"
    static let emptyInboxMeetBuddies = "去找搭子"
    static let emptyInboxOpenStrangers = "查看陌生人信箱"
    static let startChatTitle = "发起聊天"
    static let startChatFooter = "选一位好友开始聊天；选多位好友将创建群聊。"
    static let startChatEmptyTitle = "暂无可选好友"
    static let startChatEmptyDescription = "先在搭子页认识同好，或接受好友申请后，再来发起聊天。"
    static let startChatConfirm = "完成"
    static let startChatSearch = "搜索好友"
    static let markAllRead = "全部标为已读"

    // MARK: - Shared chrome

    static let add = "添加"
    static let more = "更多"
    static let cancel = "取消"
    static let close = "关闭"
}
