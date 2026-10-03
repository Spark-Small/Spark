//
//  CommunityBrowseCopy.swift
//  坐标系
//
//  广场浏览 / 筛选 / 空态文案。
//

import Foundation

enum CommunityBrowseCopy {
    static let rootTitle = "广场"
    static let embeddedTitle = "活动分享"
    static let embeddedEntryTitle = "活动分享"
    static let embeddedEntrySubtitle = "复盘与种草"
    static let embeddedEntryEmptyPreview = "看看大家分享的复盘与路线"
    static func embeddedEntryCountPreview(_ count: Int) -> String {
        "共 \(count) 条分享，点进看看最新复盘"
    }
    static let openBuddyProfile = "查看搭子主页"
    static let loadFailedMessage = "暂时无法加载广场，请下拉重试"
    static let loadFailedTitle = "加载失败"
    static let emptyTitle = "还没有分享"
    static let emptyDescription = "把好玩的局、路线和探店记下来，让更多人看见"
    static let retryLoad = "重试"
    static let searchPrompt = "搜索分享、作者或标签"
    static let composeAccessibility = "发分享"

    static let filterAll = "全部"
    static let filterFollowing = "关注"
    /// 有评论的分享（非私信「对话」）。
    static let filterConversation = "热议"
    /// 关联你参加/主办的活动，或正文提到你（非纯 @ 社交 Inbox）。
    static let filterMention = "与我相关"
    /// 发现未关注作者的供给（与「关注」互斥）；切勿写成「你关注的用户」。
    static let filterPeopleYouFollow = "发现作者"
    static let filterBarAccessibility = "广场筛选"

    static let filterAllHint = "显示全部可见分享"
    static let filterFollowingHint = "只看已关注作者的分享"
    static let filterPeopleYouFollowHint = "发现尚未关注的作者"
    static let filterConversationHint = "只看有人评论过的分享"
    static let filterMentionHint = "与你参加或主办的活动相关，或正文提到你"

    static let feedEmptyFiltered = "这个筛选下还没有内容"
    static let feedEmptyFilteredHint = "换个筛选看看，或去「发现作者」看看"
    static let feedEmptyFollowing = "还没有关注的人"
    static let feedEmptyFollowingHint = "去「发现作者」看看推荐，或逛逛全部分享"
    static let feedEmptyFollowingAction = "发现作者"
    static let feedEmptyDiscover = "暂时没有新作者可发现"
    static let feedEmptyDiscoverHint = "先逛「全部」，或关注几位后再回来"
    static let feedEmptyDiscoverAction = "看全部"
    static let feedEmptyConversation = "还没有热议分享"
    static let feedEmptyConversationHint = "去「全部」逛逛，参与评论后会出现在这里"
    static let feedEmptyConversationAction = "看全部"
    static let feedEmptyMention = "还没有与你相关的分享"
    static let feedEmptyMentionHint = "参加活动或发分享后，关联内容会出现在这里"
    static let feedEmptyMentionAction = "看全部"
    static let viewShare = "查看分享"
    static let openPostDetailHint = "打开分享详情"
    static let feedMediaDoubleTapLikeHint = "左右滑动切换图片，双击点赞"
    /// 远程写未开：诚实披露本机可见，禁止暗示全网已达。
    static let publishSuccess = "分享已保存到本机广场"
    static let reportSubmitted = "已提交举报，该分享已从你的信息流隐藏"
    static let postMissingTitle = "分享不存在"
    static let postMissingDescription = "可能已被删除，或尚未同步到本机。"
    static let detailTitle = "分享详情"
    static let commentsHeader = "评论"
    static let commentsEmpty = "还没有评论，来抢沙发吧"
    static let commentsPlaceholder = "我来说两句…"
    static let commentsSheetTitle = "评论"
    static func commentsSheetTitle(count: Int) -> String {
        "评论 \(count)"
    }
    static let moreActions = "更多"
    static let deletePost = "删除"
    static let reportPost = "举报"
    static let deleteConfirmTitle = "删除这条分享？"
    static let deleteConfirmMessage = "删除后无法恢复"
    static let reportSheetTitle = "举报这条分享"
    static let reportSheetMessage = "选择举报原因。举报后内容会从你的信息流中隐藏。"
    static let reportReasons = ["骚扰辱骂", "欺诈广告", "色情低俗", "其他"]
    static let reportFooter = "我们会尽快核查。恶意举报可能影响账号权限。"
    static let cancel = "取消"
    static let shareFallbackTitle = "分享"
    static let mediaPhoto = "分享图片"
    static func mediaPhotoPage(index: Int, total: Int) -> String {
        "分享图片，第 \(index) 张，共 \(total) 张"
    }
    static func mediaPhotosAccessibility(count: Int) -> String {
        "含 \(count) 张图片"
    }
    static let mediaVideo = "视频"
    static let relateActivitySection = "关联活动（可选）"
    static func relatedActivityLabel(_ title: String) -> String {
        "来自 · \(title)"
    }
    static let relateActivityNone = "不关联"
    static let relateActivityEmptyHint = "可关联你参加或发起的未结束活动；没有可选时仅发纯分享。"
}
