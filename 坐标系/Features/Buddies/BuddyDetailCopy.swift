//
//  BuddyDetailCopy.swift
//  坐标系
//
//  搭子 / 陪玩详情文案。
//

import Foundation

nonisolated enum BuddyDetailCopy {
    static let greet = "打招呼"
    static let invite = "邀约一起"
    static let book = "预约"
    static let quickBook = "预约"
    static let bookUnavailable = "暂不可约"

    static let greetAccessibilityHint = "打开与对方的消息或好友申请"
    static let inviteAccessibilityHint = "选择活动并发出本机邀约"
    static let bookAccessibilityHint = "选择时间并提交预约，接单后需支付"

    static let moreMenu = "更多"
    static let notInterested = "不感兴趣"
    static let report = "举报"
    static let block = "拉黑"
    static let cancel = "取消"
    static func reportTitle(_ nickname: String) -> String { "举报 \(nickname)" }
    static func blockTitle(_ nickname: String) -> String { "拉黑 \(nickname)？" }
    static let reportHarassment = "骚扰或不适内容"
    static let reportFakeProfile = "虚假资料"
    static let reportMessage = "选择举报原因。我们会尽快核查。"
    static let blockMessage = "拉黑后将不再收到对方的互动与消息。"

    static let basicInfoTitle = "基本资料"
    static let serviceTitle = "服务"
    static let serviceMenuTitle = "可约服务"
    static let serviceMenuFooter = "固定价项目可直接预约；「按天陪伴」需双方私信商议定价与行程，确认后再支付。"
    /// 详情 Form：仅理由文案。
    static let reasonTitle = "推荐理由"
    /// 详情 Form：仅兴趣胶囊（对方 `tags`，非选中态）。
    static let interestsTitle = "兴趣爱好"
    static let scheduleTitle = "可约档期"
    static let scheduleEmpty = "暂未公开档期"
    static let schedulePending = "待开放"
    static let scheduleCalendarHint = "点选「可约」日期进入预约；已满 / 待开放不可选。"
    static let relatedTitle = "可以一起去"
    static let relatedFooter = "根据 TA 常约的类型推荐"
    static let communityPostsTitle = "最近分享"
    static let performanceTitle = "接单与口碑"
    static let circleTitle = "所在俱乐部"
    static let returnToCircleHint = "返回俱乐部信息"
    static let openCircleHint = "查看俱乐部详情"
    static let trustArchiveTitle = "信任档案"
    static let reviewsTitle = "用户评价"
    static let reviewsEmpty = "暂无评价"
    static let reviewsFilteredEmpty = "暂无符合筛选的评价"
    static let reviewsComposerPlaceholder = "写下你的评价…"

    static func reviewsTitleCount(_ count: Int) -> String {
        "\(reviewsTitle) (\(count))"
    }

    static let verifiedBadge = "平台认证"
    static let distanceChipPrefix = "距你"
    static let online = "在线"
    static let available = "可约"
    static let unavailable = "档期已满"
    static let follow = "关注"
    static let following = "已关注"
    static let schedulePrevMonth = "上个月"
    static let scheduleNextMonth = "下个月"
    static func photoA11y(_ nickname: String) -> String { "\(nickname)的照片" }
    static let photoSwipeHint = "左右滑动切换照片"

    static let genderLabel = "性别"
    static let ageLabel = "年龄"
    static let heightLabel = "身高"
    static let weightLabel = "体重"
    static let cityLabel = "地区"
    static let activeLabel = "最近活跃"
    static let availabilityLabel = "空闲"
    static let occupationLabel = "身份"
    static let meetRadiusLabel = "出行"
    static let intentLabel = "我想怎么玩"
    static let serviceTypeLabel = "服务项目"
    static let specialtyLabel = "擅长"
    static let priceLabel = "价格"

    static func ageValue(_ age: Int) -> String { "\(age) 岁" }
    static func ordersValue(_ count: Int) -> String { "\(count) 单" }

    static let profileIDPrefix = "ID"
    static let publicIDLabel = "UID"
    static let statOrders = "接单数"
    static let statRating = "评分"
    static let statPositiveRate = "好评率"
    static let statResponse = "响应时长"
    static let statUnavailable = "暂无"
    static let postsEmptyTitle = "还没有动态"
    static let postsEmptyDescription = "对方在广场发布的分享会出现在这里。"
    static let scheduleInviteConfirmTitle = "用这一天发起邀约？"
    static let scheduleInviteConfirmMessage = "将打开邀约流程，选择活动后发给对方。"
    static let scheduleInviteConfirmAction = "去邀约"
}
