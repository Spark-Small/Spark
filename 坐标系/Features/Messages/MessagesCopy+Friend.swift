//
//  MessagesCopy+Friend.swift
//  坐标系
//
//  好友资料 / 申请 / UID / 陌生人信箱文案。
//

import CoordinateModels
import Foundation

extension MessagesCopy {
    // MARK: - Friend profile

    static let friendSendMessage = "发消息"
    static let friendAVCall = "语音通话"
    static let friendSetGroup = "设置好友分组"
    static let friendAddToBlacklist = "加入黑名单"
    static let friendComplaint = "投诉"
    static let friendDelete = "删除好友"
    static let friendRemarkLabel = "备注"
    static let friendRemarkPlaceholder = "添加备注名"
    static let friendGroupLabel = "分组"
    static let friendProfileTitle = "好友资料"
    static let friendContactSection = "联系与备注"
    static let friendRelationLabel = "好友"
    static let friendRoleCompanion = "陪玩"
    static let friendRoleBuddy = "同好"
    static let friendCityLabel = "城市"
    static let friendLookingForLabel = "想找"
    static let friendHostedSection = "主办活动"
    static let friendTrustArchiveLink = "信任档案"
    static let friendTrustArchiveHint = "查看认证徽章与近 90 天履约"
    static let friendGroupUngrouped = "未分组"
    /// 系统预设（不含「未分组」）；自建组走 `friendGroupCatalog`。
    static let friendGroupPresets = ["亲密好友", "同事", "同学", "其他"]
    static let friendNewGroup = "新建分组"
    static let friendNewGroupPlaceholder = "分组名称"
    static let friendNewGroupCreate = "创建"
    static let friendNewGroupHint = "创建后将把该好友移入此分组"
    static let friendNicknameLabel = "昵称"
    static let friendDeleteConfirmTitle = "删除好友？"
    static let friendDeleteConfirmMessage = "将删除与该好友的聊天记录，此操作无法撤销。"
    static let friendBlockConfirmTitle = "加入黑名单？"
    static let friendBlockConfirmMessage = "拉黑后将删除会话，且不再显示该好友。"
    static let friendBlocked = "已加入黑名单"

    static let friendSubtitle = "好友"
    static let strangerSubtitle = "陌生人"
    static let groupSubtitle = "群聊"
    static let noticeSubtitle = "通知"
    static let groupOwnerBadge = "群主"
    static let groupCreated = "你创建了群聊"
    static func memberJoined(_ name: String) -> String { "\(name)加入了群聊" }
    static func memberLeft(_ name: String) -> String { "\(name)退出了群聊" }
    static let announcementUpdated = "群主更新了群公告"
    static func groupRenamed(_ title: String) -> String { "群主修改群名为「\(title)」" }
    static func memberKicked(_ name: String) -> String { "\(name)被移出群聊" }

    static let dissolveGroup = "解散群聊"
    static let leaveGroup = "退出群聊"
    static let messageRequestsTitle = "好友请求"
    static let messageRequestsEmptyTitle = "没有好友请求"
    static let messageRequestsEmptyDescription = "别人加你为好友时，会出现在这里。"
    static let outgoingFriendRequestsSection = "等待验证"
    static let outgoingFriendRequestPending = "已发送"
    static let strangerMailboxTitle = "陌生人信箱"
    static let strangerMailboxEmptyTitle = "还没有陌生人会话"
    static let strangerMailboxEmptyDescription = "陌生人发来的消息会出现在这里。点进可查看聊天；不会与好友申请混在一起。"
    static let strangerMailboxOpenHint = "打开与该陌生人的会话"
    static let strangerMailboxMoveToInbox = "移入收件箱"
    static let strangerMailboxDelete = "删除会话"
    static let messageRequestPreviewEmpty = "无预览内容"
    static let accept = "接受"
    static let acceptRequestHint = "接受好友申请"
    static let ignoreRequestHint = "忽略此好友申请"

    static let addFriendByUID = "通过 UID 添加"
    static let addFriendByUIDTitle = "添加好友"
    static let addFriendByUIDField = "对方 UID"
    static let addFriendByUIDPlaceholder = "9 位数字"
    static let addFriendByUIDAction = "添加"
    static let addFriendByUIDFooter = "输入对方对外 UID（9 位数字）。发送后需对方同意才能成为好友。可在「我的 → 账号与安全」查看自己的 UID。"
    static let addFriendByUIDInvalid = "请输入 9 位数字 UID"
    static let addFriendByUIDNotFound = "未找到该 UID 对应的用户"
    static let addFriendByUIDIsSelf = "不能添加自己"
    static func addFriendByUIDAlreadyFriend(_ name: String) -> String {
        "「\(name)」已是好友"
    }
    static func addFriendByUIDSuccess(_ name: String) -> String {
        "已向「\(name)」发送好友申请，对方同意后即可开始聊天"
    }
    static func addFriendByUIDPending(_ name: String) -> String {
        "已向「\(name)」发送过申请，请等待对方验证"
    }
    static func addFriendByUIDGreeting(uid: String) -> String {
        "你好，我通过 UID \(UserPublicID.formatDisplay(uid)) 加你为好友"
    }
    static let addFriendAction = "加好友"
    static let addFriendPeerTitle = "添加好友"
    static let addFriendVerifyField = "验证信息"
    static let addFriendVerifyPlaceholder = "向对方介绍一下自己"
    static let addFriendVerifyFooter = "对方通过后才能开始聊天。请礼貌说明来意。"
    static let addFriendSend = "发送申请"
    static let friendRequestPending = "等待验证"
    static let friendRequestSentTitle = "申请已发送"
    static func friendRequestSentMessage(_ name: String) -> String {
        "已向「\(name)」发送好友申请，对方通过后即可聊天"
    }
    static let friendRequestPendingDescription = "你已发送好友申请，请等待对方通过"
    static let defaultFriendRequestMessage = "你好，想加你为好友"
    static func addFriendAlreadyFriend(_ name: String) -> String {
        "「\(name)」已是好友"
    }
    static let copyUID = "复制 UID"
    static func peerGroupTitle(_ names: [String]) -> String {
        let shown = names.prefix(3)
        let joined = shown.joined(separator: "、")
        if names.count > shown.count {
            return "\(joined)等"
        }
        return joined
    }
}
