//
//  MessagesCopy+Conversation.swift
//  坐标系
//
//  会话列表滑动 / 会话详情 chrome / 群详情文案。
//

import Foundation

extension MessagesCopy {
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
        "将删除与「\(title)」的聊天，此操作无法撤销。"
    }

    static let clearHistoryTitle = "清空聊天记录？"
    static let clearHistoryConfirm = "清空"
    static let clearHistoryMessage = "将删除此对话中的全部消息，会话仍会保留在列表中。"
    static let clearHistoryDone = "已清空聊天记录"
    static let clearedHistoryPreview = "无消息"

    static let leavePeerGroupTitle = "退出群聊？"
    static let leavePeerGroupMessage = "退出后本地会话将删除，且不再显示此群消息。"
    static let dissolveGroupTitle = "解散群聊？"
    static let dissolveGroupMessage = "解散后此群聊将从列表中移除（本机）。"

    // MARK: - Conversation chrome

    static let pinConversation = "置顶会话"
    static let unpinConversation = "取消置顶"
    static let muteOn = "开启免打扰"
    static let muteOff = "关闭免打扰"
    static let viewProfile = "查看资料"
    static let deleteConversation = "删除会话"
    static let copy = "拷贝"
    static let copied = "已拷贝"
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

    static let groupDetailTitle = "群详情"
    static func groupInfoTitle(_ count: Int) -> String { "群信息 (\(count))" }
    static let groupLeaveConfirmTitle = "退出群聊？"
    static let groupLeaveConfirmMessage = "退出后将离开本群，可在通讯录或活动中重新加入。"
    static let groupInviteEmptyTitle = "暂无可邀请的好友"
    static let groupInviteEmptyDescription = "先添加好友，再邀请进群。"
    static let circleInfo = "圈子信息"
    static let groupClearHistory = "清空聊天记录"
    static let groupInvite = "邀请进群"
    static let groupInviteMembers = "邀请成员"
    static let groupMemberPickerTitle = "选择联系人"
    static let groupLeave = "退出群聊"
    static let groupAnnouncementEmpty = "暂无公告"

    static let sendPlaceholder = "发消息..."
    static let noticePlaceholder = "通知不支持回复"
    static let imagePlaceholder = "[图片]"
    static let send = "发送"
    static let emptyThreadTitle = "开始聊天"
    static func emptyThreadDescription(peerName: String) -> String {
        "发一条消息，和 \(peerName) 打个招呼"
    }
    static let outboundBlockedNotice = "你已发送 3 条消息，请等待对方回复后再联系"
    static let liked = "已点赞"
    static let like = "喜欢"
    static let unlike = "取消喜欢"
    static let reply = "回复"
    static let deleteMessage = "删除"
    static let editMessage = "编辑"
    static let unsendMessage = "撤回"
    static let forwardMessage = "转发"
    static let editedStatus = "已编辑"
    static let messageUnsent = "你撤回了一条消息"
    static let editMessageTitle = "编辑消息"
    static let editMessageSave = "存储"
    static let editMessageUnavailable = "已超过可编辑时间"
    static let unsendUnavailable = "已超过可撤回时间"
    static let forwardPickerTitle = "转发到"
    static let forwardEmptyTitle = "没有可转发的会话"
    static let forwardDone = "已转发"
    static let localVoiceTitle = "发送本机语音"
    static let localVoiceMessage = "不录音、不上传；仅在本机会话插入语音气泡。真语音通道需 B5。"
    static let localVoiceSend = "发送 3 秒气泡"
    static let cancelReply = "取消回复"
    static let bubbleA11yHint = "轻点查看时间，连点两下喜欢"
    static func replyingTo(_ name: String) -> String { "回复 \(name)" }
    static let dayToday = "今天"
    static let dayYesterday = "昨天"
    static let noticeAccessibility = "平台通知"
    static let activeNow = "在线"
    static let seenStatus = "已读"
    static let deliveredStatus = "已送达"
    static let sentStatus = "已发送"
    static let failedStatus = "发送失败"
    static let retrySend = "重发"
    static let loadOlderMessages = "加载更早消息"
    static let photoImportFailed = "无法导入所选图片，请换一张再试"
}
