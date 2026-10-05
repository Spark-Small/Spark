//
//  BuddyOrgJoinCopy.swift
//  坐标系
//
//  组织加入 / 投诉 / 通用搭子反馈文案。
//

import Foundation

nonisolated enum BuddyOrgJoinCopy {
    static let confirmJoinCTA = "确认加入"
    static let cancel = "取消"
    static let close = "关闭"
    static let ok = "好的"
    static let send = "发送"
    static let enterChat = "进入群聊"
    static let inviteLocalFooter = "成员邀请发送尚未接入，当前不会假装发出。"
    static let inviteUnavailable = "邀请发送尚未开放，本次未发出。"

    static let confirmCircleTitle = "加入俱乐部"
    static let confirmGuildTitle = "关注工会"

    static let confirmChatRowTitle = "加入后"
    static let confirmChatRowValue = "成为俱乐部成员"
    static let confirmChatFooter = "俱乐部与单场活动无绑定；群聊可在资料页进入，也可在「消息」查看。"

    static let confirmGuildRowTitle = "关注后"
    static let confirmGuildRowValue = "查看工会陪玩"
    static let confirmGuildFooter = "可在工会资料中随时取消关注。"

    static let report = "投诉"
    static let clearChat = "清空"
    static let clearChatConfirmTitle = "清空聊天记录？"
    static let clearChatConfirmBody = "仅清除本机聊天记录，不影响其他成员。"
    static let clearChatDone = "聊天记录已清空"
    static let alertTitle = "提示"
    static let reportSubmittedTitle = "投诉已提交"
    static let inviteMember = "邀请"
    static let inviteMemberA11y = "邀请成员"
    static let cityRow = "所在城市"
    static let leaveCircleBody = "退出后将离开俱乐部群聊，成员设置会清除，可随时重新加入。"
    static let leaveGuildBody = "退出后成员设置会清除，可随时重新加入。"
    static let chatNameUpdated = "群聊名称已更新"
    static func evidenceA11y(_ index: Int) -> String { "证据 \(index)" }
    static func attachmentCount(_ count: Int) -> String { "附件 \(count) 张" }

    static func createdClub(_ name: String) -> String { "已创建「\(name)」" }
    static func joinedClub(_ name: String) -> String { "已加入「\(name)」" }
    static func followedGuild(_ name: String) -> String { "已关注「\(name)」" }
    static func leftClub(_ name: String) -> String { "已退出「\(name)」" }
    static func unfollowedGuild(_ name: String) -> String { "已取消关注「\(name)」" }
    static func invitedCount(_ count: Int, label: String) -> String {
        "已邀请 \(count) 人加入「\(label)」"
    }
}

/// 搭子域通用反馈文案（toast / light feedback）
nonisolated enum BuddyFeedbackCopy {
    static let persistFailed = "保存失败，请稍后重试"
    static let reportSubmitted = "已提交举报，并减少推荐"
    static let hideSimilar = "已减少类似推荐"
    static let remoteInviteSubmitFailed = "邀约已保存在本机，同步服务器失败，稍后会重试"
    static let remoteClubSyncFailed = "俱乐部已保存在本机，同步服务器失败，可稍后重试"
    static let remoteBookingSubmitFailed = "预约已保存在本机，同步服务器失败，将继续尝试拉取状态"
    static let activityInviteTitle = "活动邀约"
    static func inviteSent(nickname: String, activityTitle: String) -> String {
        "已邀请 \(nickname) 参加 \(activityTitle)"
    }
    static func inviteAccepted(_ nickname: String) -> String { "\(nickname) 已接受邀约" }
    static func inviteDeclined(_ nickname: String) -> String { "\(nickname) 婉拒了邀约" }
}
