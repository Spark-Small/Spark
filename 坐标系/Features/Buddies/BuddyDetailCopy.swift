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
    static let book = "预约陪玩"
    static let quickBook = "快速下单"
    static let bookUnavailable = "暂不可约"

    static let basicInfoTitle = "基本资料"
    static let aboutTitle = "关于"
    static let serviceTitle = "服务"
    static let serviceMenuTitle = "可约服务"
    static let serviceMenuFooter = "固定价项目可直接下单；「按天陪伴」需双方私信商议定价与行程，确认后再支付。"
    static let matchTitle = "共同兴趣"
    static let reasonTitle = "推荐理由"
    static let scheduleTitle = "可约档期"
    static let scheduleEmpty = "暂未公开档期"
    static let scheduleCalendarHint = "点选「可约」日期即可下单，无需先私信沟通。"
    static let relatedTitle = "可以一起去"
    static let relatedFooter = "根据 TA 常约的类型推荐"
    static let performanceTitle = "接单与口碑"
    static let circleTitle = "所在圈子"
    static let returnToCircleHint = "返回圈子信息"
    static let openCircleHint = "查看圈子详情"
    static let trustArchiveTitle = "信任档案"
    static let reviewsTitle = "用户评价"
    static let reviewsEmpty = "暂无评价"
    static let reviewsFilteredEmpty = "暂无符合筛选的评价"
    static let reviewsFooter = "评价来自完成履约的预约，仅供参考。"
    static let reviewsSeeAll = "查看全部"
    static let reviewsComposerPlaceholder = "写下你的评价…"

    static func reviewsTitleCount(_ count: Int) -> String {
        "\(reviewsTitle) (\(count))"
    }

    static let verifiedBadge = "平台认证"
    static let distanceChipPrefix = "距你"
    static let online = "在线"
    static let available = "可约"
    static let unavailable = "档期已满"

    static let genderLabel = "性别"
    static let ageLabel = "年龄"
    static let heightLabel = "身高"
    static let weightLabel = "体重"
    static let cityLabel = "地区"
    static let activeLabel = "最近活跃"
    static let availabilityLabel = "空闲"
    static let serviceTypeLabel = "服务项目"
    static let specialtyLabel = "擅长"
    static let priceLabel = "价格"
    static let ordersLabel = "成单"
    static let responseLabel = "响应"

    static func ageValue(_ age: Int) -> String { "\(age) 岁" }
    static func ordersValue(_ count: Int) -> String { "\(count) 单" }

    static func photosCount(_ count: Int) -> String { "\(count) 张" }

    static let profileIDPrefix = "ID"
    static let statOrders = "接单数"
    static let statRating = "评分"
    static let statPositiveRate = "好评率"
    static let statResponse = "响应时长"
    static let statActive = "活跃"

    static func responseDurationShort(_ text: String) -> String {
        let digits = text.filter(\.isNumber)
        if text.localizedCaseInsensitiveContains("小时"), let hours = Int(digits.prefix(1)), hours > 0 {
            return "\(hours)h"
        }
        if let minutes = Int(digits.prefix(2)), minutes > 0 {
            return "\(minutes)分"
        }
        return text
    }
}

// MARK: - 陪玩发现

nonisolated enum BuddyPaidBrowseCopy {
    static let quickMatchTitle = "快速匹配"
    static let quickMatchSubtitle = "优先可约"
    static let voicePartyTitle = "语音派对"
    static let voicePartySubtitle = "多人连麦"

    static let serviceTypeAll = "全部"

    static let filterServiceTypeTitle = "服务类型"
    static let filterServiceTypeFooter = "筛选陪玩服务项目；不限则展示全部。"
}

// MARK: - 语音介绍

nonisolated enum BuddyVoiceIntroCopy {
    static let publicSectionTitle = "语音介绍"
    static let publicFallbackCaption = "听听 TA 的声音"
    static let editRowTitle = "语音介绍"
    static let editEmptyValue = "未添加"
    static let editAddTitle = "添加语音介绍"
    static let recordSheetTitle = "语音介绍"
    static let recordHint = "按住下方按钮模拟录制；松手完成。正式版将接入麦克风与上传。录好后会展示在你的搭子资料页。"
    static let captionLabel = "一句话说明（可选）"
    static let captionPlaceholder = "例如：周末常约羽毛球，欢迎打招呼"
    static let holdToRecord = "按住录音"
    static let releaseToFinish = "松手完成"
    static let save = "保存"
    static let removeVoice = "删除语音"
    static let playAccessibility = "播放语音介绍"
    static let pauseAccessibility = "暂停播放"
}

// MARK: - 预约 / 邀约流程

nonisolated enum BuddyBookingFlowCopy {
    static let selectStepTitle = "选择档期"
    static let confirmStepTitle = "确认预约"
    static let nextStep = "下一步"
    static let submitBooking = "提交预约"
    static let unavailableTitle = "暂不可约"
    static let unavailableBody = "对方档期已满或暂停接单，可先打招呼沟通时间。"
    static let conflictHint = "该时间与已有预约冲突，请改选其他时段。"
    static let submittedHint = "接单后系统会通知你支付；也可在「我的 → 陪玩预约」查看进度。"
    static let successTitle = "支付成功"
    static let successSubtitle = "预约凭证已生成，开场前会提醒你。"
    static let inviteConfirmTitle = "确认邀约"
    static let inviteConfirmHint = "对方接受后会通知你，也可在消息里跟进。"
    static let inviteNotePlaceholder = "补充说明（可选）"
    static let inviteSend = "发送邀约"
    static let inviteEmptyTitle = "暂无可邀约的活动"
    static let inviteEmptyBody = "先报名或发布一场活动，再邀请搭子一起参加。"
    static let inviteSuccessTitle = "邀约已发送"
    static func inviteSuccessSubtitle(_ nickname: String) -> String {
        "已通知 \(nickname)，等待对方回执"
    }
    static let freeScheduleHint = "点选有空档的日期，可邀约 TA 一起参加活动。"

    static let submittedTitle = "预约已提交"
    static let done = "完成"
    static let cancel = "取消"
    static let back = "返回"
    static let loadingOrder = "加载订单…"
    static let orderProcessing = "订单处理中"
    static let withdrawBooking = "撤销预约"
    static let waitInBackground = "在后台等待"
    static let gotIt = "知道了"
    static let contactCompanion = "联系陪玩"
    static let openMyBookings = "查看陪玩预约"
    static let companionLabel = "陪玩"
    static let durationLabel = "时长"
    static let feeLabel = "费用"
    static let hoursUnit = "小时"

    static func submittedStatus(for record: BuddyBookingRecord) -> String {
        switch record.status {
        case .pendingConfirm:
            return "已提交，等待 \(record.companionNickname) 确认"
        case .awaitingPayment:
            return "\(record.companionNickname) 已接单，请完成支付"
        case .cancelled:
            return "订单已取消"
        default:
            return record.status.rawValue
        }
    }
}
