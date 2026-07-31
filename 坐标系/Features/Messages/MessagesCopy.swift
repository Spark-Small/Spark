//
//  MessagesCopy.swift
//  坐标系
//
//  消息：业务只保留「好友」与「群聊」两类社交会话。
//

import Foundation

/// Pure string constants — opt out of default MainActor isolation so values can be
/// used as default parameter expressions (which are evaluated in a nonisolated context).
nonisolated enum MessagesCopy {
    // MARK: - Inbox / filters

    static let searchPrompt = "搜索好友、群聊和聊天记录"
    static let searchSectionConversations = "好友与群聊"
    static let searchSectionHistory = "聊天记录"
    static let filterFriends = "好友聊天"
    static let filterGroups = "群聊"
    static let circleGroupSubtitle = "组织"
    static let friendsListTitle = "通讯录"
    static let friendsListEmptyTitle = "通讯录为空"
    static let friendsListEmptyDescription = "发起好友聊天或接受好友申请后，联系人会出现在这里"
    static let friendsListSearch = "搜索通讯录"
    static let friendsListChat = "发消息"

    // MARK: - Friend profile

    static let friendSendMessage = "发消息"
    static let friendAVCall = "音视频通话"
    static let friendCall = "发起通话"
    static let friendEditRemark = "编辑备注"
    static let friendSetGroup = "设置好友分组"
    static let friendAddToBlacklist = "加入黑名单"
    static let friendComplaint = "投诉"
    static let friendDelete = "删除好友"
    static let friendRemarkLabel = "备注"
    static let friendRemarkPlaceholder = "添加备注名"
    static let friendGroupLabel = "分组"
    static let friendGroupUngrouped = "未分组"
    static let friendGroupOptions = ["未分组", "亲密好友", "同事", "同学", "其他"]
    static let friendNicknameLabel = "昵称"
    static let friendDeleteConfirmTitle = "删除好友？"
    static let friendDeleteConfirmMessage = "将删除与该好友的聊天记录，此操作无法撤销。"
    static let friendBlockConfirmTitle = "加入黑名单？"
    static let friendBlockConfirmMessage = "拉黑后将删除会话，且不再显示该好友。"
    static let friendSave = "保存"
    static let friendDeleted = "已删除好友"
    static let friendBlocked = "已加入黑名单"
    static let friendMomentsSection = "朋友圈"
    static let friendMomentsEmpty = "还没有动态图片"
    static let friendCommunityPosts = "社区动态"
    static let friendCommunityPostsEmpty = "还没有社区分享"
    static let friendSeePost = "查看动态"

    static let friendSubtitle = "好友"
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
    static let messageRequestsEmpty = "暂无消息请求"
    static let messageRequestsInboxEntry = "消息请求"
    static let messageRequestsPreview = "预览"

    static let emptyInboxTitle = "还没有会话"
    static let emptyInboxDescription = "在搭子页打招呼，或参加活动后，好友与群聊会出现在这里"
    static let startChat = "发起聊天"
    static let startChatTitle = "发起聊天"
    static let startChatFooter = "选一位好友开始聊天；选多位好友将创建群聊。"
    static let startChatEmptyTitle = "暂无可选好友"
    static let startChatEmptyDescription = "先在搭子页认识同好，或接受好友申请后，再来发起聊天。"
    static let startChatConfirm = "完成"
    static let startChatSearch = "搜索好友"
    static func peerGroupTitle(_ names: [String]) -> String {
        let shown = names.prefix(3)
        let joined = shown.joined(separator: "、")
        if names.count > shown.count {
            return "\(joined)等"
        }
        return joined
    }
    static let markAllRead = "全部标为已读"

    // MARK: - Swipe / row actions

    static let pin = "置顶"
    static let unpin = "取消置顶"
    static let mute = "免打扰"
    static let unmute = "取消免打扰"
    static let markRead = "标为已读"
    static let markUnread = "标为未读"
    static let delete = "删除"

    static let deleteDialogTitle = "删除会话？"
    static let deleteDialogConfirm = "删除"
    static let deleteDialogCancel = "取消"
    static func deleteDialogMessage(title: String) -> String {
        "将删除与「\(title)」的聊天记录，此操作无法撤销。"
    }

    // MARK: - Conversation chrome

    static let conversationMissing = "会话不存在"
    static let add = "添加"
    static let more = "更多"
    static let pinConversation = "置顶会话"
    static let unpinConversation = "取消置顶"
    static let muteOn = "开启免打扰"
    static let muteOff = "关闭免打扰"
    static let viewProfile = "查看资料"
    static let activityDetail = "活动详情"
    static let deleteConversation = "删除会话"
    static let copy = "拷贝"
    static let copied = "已拷贝"
    static let blockedAndRemoved = "已拉黑并删除会话"
    static let reportSubmitted = "已提交举报"
    static let reactionMenu = "表情回应"
    static let clearReaction = "清除回应"
    static let mentionMembers = "@成员"
    static let memberFallback = "成员"
    static let defaultGreeting = "你好，想一起玩吗？"
    static let demoAutoReplies = [
        "好的，收到～",
        "嗯嗯，到时候见！",
        "可以呀",
        "哈哈好，我记下了"
    ]
    static let activityCardLabel = "活动"

    // Group manage / requests / report
    static let groupInfoSection = "群信息"
    static let groupNameLabel = "群名称"
    static let groupMembersLabel = "成员"
    static func groupMemberCount(_ count: Int) -> String { "\(count) 人" }
    static let groupAnnouncementSection = "群公告"
    static let groupAnnouncementPlaceholder = "更新公告"
    static let groupPublishAnnouncement = "发布公告"
    static let groupMembersSection = "成员"
    static let groupKick = "移出"
    static let groupSetAdmin = "设为管理员"
    static let groupRemoveAdmin = "取消管理员"
    static let groupOwnerSection = "群主"
    static let groupRoleSection = "角色管理"
    static let groupSaveName = "保存群名"
    static let groupInvitePlaceholder = "邀请昵称"
    static let groupInvite = "邀请进群"
    static let groupInviteMembers = "邀请成员"
    static let groupMemberPickerTitle = "选择联系人"
    static let groupDismiss = "解散群聊"
    static let groupLeave = "退出群聊"
    static let groupOpenActivity = "查看关联活动"
    static let friendRequestsSection = "好友申请"
    static let messageRequestsSection = "消息请求"
    static let accept = "接受"
    static let ignore = "忽略"
    static let reportTargetSection = "举报对象"
    static let reportReasonSection = "原因"
    static let reportSubmit = "提交举报"
    static let reportFooter = "我们会尽快核查。恶意举报可能影响账号权限。"
    static func unreadA11y(_ count: Int) -> String { "未读 \(count) 条" }
    static func eventTimeA11y(_ text: String) -> String { "活动时间 \(text)" }
    static let sendPlaceholder = "发消息..."
    static let noticePlaceholder = "通知不支持回复"
    static let imagePlaceholder = "[图片]"
    static let send = "发送"
    static let emptyThreadTitle = "开始聊天"
    static func emptyThreadDescription(peerName: String) -> String {
        "发一条消息，和 \(peerName) 打个招呼"
    }
    static let cancel = "取消"
    static let close = "关闭"
    static let read = "已读"
    static let liked = "已点赞"
    static let like = "喜欢"
    static let unlike = "取消喜欢"
    static let reply = "回复"
    static let deleteMessage = "删除"
    static let attach = "更多"
    static let attachCamera = "相机"
    static let cancelReply = "取消回复"
    static let voiceCall = "语音通话"
    static let videoCall = "视频通话"
    static let callConnecting = "连接中"
    static let callRinging = "等待接听"
    static let callMuted = "静音"
    static let callSpeaker = "扬声器"
    static let callCamera = "摄像头"
    static let callEnd = "挂断"
    static let callBackToChat = "返回聊天"
    static let callLocalModeHint = "本地开发态模拟通话，不会接通真实音视频流。"
    static let callHistoryTitle = "通话记录"
    static let callHistoryEmpty = "暂无通话记录"
    static let callHistoryRedial = "回拨"
    static let bubbleA11yHint = "轻点查看时间，连点两下喜欢"
    static func replyingTo(_ name: String) -> String { "回复 \(name)" }
    static let dayToday = "今天"
    static let dayYesterday = "昨天"
    static let noticeAccessibility = "平台通知"
    static let activeNow = "在线"
    static let seenStatus = "已读"
    static let deliveredStatus = "已送达"

    // MARK: - Attach / social sheets

    static let attachPhoto = "照片"
    static let attachVoice = "语音"
    static let attachLocation = "位置"
    static let attachActivity = "活动卡片"
    static let attachTransfer = "转账"
    static let attachSticker = "表情"
    static let groupManage = "群管理"
    static let blockUser = "拉黑"
    static let reportUser = "举报"
    static let reportTitle = "举报"
    static let reportReasons = ["骚扰辱骂", "欺诈广告", "色情低俗", "其他"]
    static let transferTitle = "转账"
    static let transferAmountHeader = "转账金额"
    static let transferAmountPlaceholder = "金额"
    static let transferConfirm = "确认转账"
    static let transferDemoFooter = "从钱包余额扣款；取消或过期后退回。本地演示，无真实扣款。"
    static let transferDemoBadge = "本地转账"
    static let transferDefaultAmount = "20"
    static let transferAccept = "确认收款"
    static let transferCancel = "取消转账"
    static let transferRefund = "退回转账"
    static let transferPending = "待收款"
    static let transferAccepted = "已收款"
    static let transferCancelled = "已取消"
    static let transferRefunded = "已退回"
    static let transferExpired = "已过期"
    static func transferExpiresIn(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        if hours > 0 { return "\(hours) 小时 \(minutes) 分钟后过期" }
        if minutes > 0 { return "\(minutes) 分钟后过期" }
        return "即将过期"
    }
    static func transferExpiredNotice(amount: Double) -> String {
        "转账 ¥\(String(format: "%.2f", amount)) 已过期"
    }
    static let groupAnnouncementEmpty = "暂无公告"
    static let groupRenamePlaceholder = "修改群名"
    static let currentLocation = "当前位置"
    static let mapLocationFallback = "地图位置"
    static func transferStatusLabel(_ status: TransferStatus) -> String { status.rawValue }
    static func requestSourceLabel(_ source: MessageRequestSource) -> String { source.rawValue }
}
