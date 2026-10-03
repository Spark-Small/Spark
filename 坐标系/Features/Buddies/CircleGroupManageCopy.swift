//
//  CircleGroupManageCopy.swift
//  坐标系
//
//  俱乐部群管理与资料页文案（含确认 Sheet）。
//

import Foundation

nonisolated enum CircleGroupCopy {
    static let chatName = "群聊名称"
    static let qrCode = "群二维码"
    static let announcement = "群公告"
    static let manage = "群管理"
    static let searchChat = "查找聊天内容"
    static let searchUnavailable = "查找聊天内容即将开放"
    static let muteNotifications = "消息免打扰"
    static let mutedNotify = "以下消息仍然通知"
    static let pinChat = "置顶聊天"
    static let showMemberNicknames = "显示群成员昵称"
    static let clearHistory = "清空聊天记录"
    static let allowJoinViaQR = "二维码进群"
    static let joinRequiresApproval = "进群需要群主/群管理员确认"
    static let onlyAdminCanRename = "仅群主/群管理员可修改群聊名称"
    static let transferOwnership = "群主管理权转让"
    static let owner = "群主"
    static let admins = "群管理员"
    static let addAdmin = "添加群管理员"
    static let removeAdmin = "移除"
    static let adminFooter = "群管理员可确认进群申请，并协助维护群秩序。最多 3 名，不含群主。"
    static let dissolve = "解散该俱乐部"
    static let notifyAtMe = "@我"
    static let notifyAtAll = "@所有人"
    static let notifyAnnouncement = "群公告"
    static let mutedNotifyFooter = "开启消息免打扰后，仍可接收选定类型的提醒。"
}

nonisolated enum CircleGroupManageCopy {
    static let cancel = "取消"
    static let close = "关闭"
    static let save = "保存"
    static let remove = "移除"

    static func qrHint(_ title: String) -> String { "扫码加入「\(title)」" }
    static let renameTitle = "修改群聊名称"
    static let transferEmpty = "暂无可转让的成员"
    static let transferFooter = "转让后，你将失去群主权限，对方成为新群主。"
    static let addAdminEmpty = "暂无可添加的成员"
    static func addAdminFooter(max: Int) -> String {
        "群管理员可协助确认进群申请；不含群主，最多 \(max) 名。"
    }
    static let groupNicknameTitle = "我在本群的昵称"
    static func groupNicknameFooter(realName: String) -> String {
        "保存后，其他成员在群内将看到「\(realName)（本群昵称）」形式展示。"
    }

    static let dissolveTitle = "解散该俱乐部？"
    static let dissolveBody = "解散后俱乐部群聊将移除，成员需重新加入。"
    static let removeAdminTitle = "移除群管理员？"
    static let groupNicknameField = "本群昵称"
    static let ownerRulesFooter = "进群与改名规则对本俱乐部群聊生效。"
    static let nonOwnerRulesFooter = "仅群主可修改以下设置。"
    static func removeAdminBody(_ name: String) -> String {
        "将取消「\(name)」的群管理员身份。"
    }
}
