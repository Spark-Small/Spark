//
//  ProfileMembershipCopy.swift
//  坐标系
//
//  会员中心文案（无后端：StoreKit Configuration + 本机投影）。
//

import Foundation

enum ProfileMembershipCopy {
    static let navigationTitle = "会员中心"
    static let brandTitle = "坐标系会员"
    static let tagline = "优先提醒、会员标识与更多收藏空间。"

    static let statusSection = "状态"
    static let statusLabel = "订阅状态"
    static let statusActive = "已开通"
    static let statusInactive = "未开通"
    static let planLabel = "当前方案"
    static let planMonthly = "坐标系会员（月）"
    static let renewLabel = "下次续费/到期"
    static let sourceLabel = "开通来源"
    static let sourceStoreKit = "App Store 订阅"
    static let sourceDemo = "本地演示（DEBUG）"
    static let sourceFooterStoreKit = "权益以本机 App Store 交易为准；尚未接入会员服务端对账。"
    static let sourceFooterDemo = "DEBUG 演示权益仅存本机，刷新不会被清掉；正式购买请走 App Store。"

    static let benefitsSection = "会员权益"
    static let benefitPriority = "活动优先提醒"
    static let benefitBadge = "专属身份标识"
    static let benefitLibrary = "更多内容收藏空间"
    static let benefitsFooter = "开通后可在活动、社区与消息中展示会员标识。"

    static let manageSection = "订阅"
    static let manageSubscriptions = "管理订阅"
    static let restorePurchases = "恢复购买"
    static let refreshStatus = "刷新状态"
    static let manageFooter = "在系统订阅页可更改方案、取消或查看账单。数字会员仅通过 App Store 购买。"

    static let unavailableTitle = "暂时无法加载订阅"
    static let unavailableDescription = "请确认已选用 StoreKit 配置文件，或稍后重试。无后端时会员购买走 Apple 本地交易。"
    static let retryLoad = "重新加载"

    static let youthTitle = "青少年模式已开启"
    static let youthSystemImage = "figure.and.child.holdinghands"

    static let alertTitle = "无法开通"
    static let alertOK = "好的"
    static let insufficientBalance = "余额不足，请先前往钱包充值。"
    static let restoreFailedPrefix = "恢复购买失败："

    static let demoActivate = "本地演示开通（钱包扣款）"
    static let demoClear = "关闭本地演示会员"
    static let demoFooterPrefix = "DEBUG：无 StoreKit 环境时可用钱包余额演示开通"
    static let demoSection = "开发调试"

    static let marketingBenefits: [(title: String, systemImage: String)] = [
        (benefitPriority, "bell.badge"),
        (benefitBadge, "checkmark.seal.fill"),
        (benefitLibrary, "bookmark.fill")
    ]

    static func planDisplayName(productDisplayName: String?) -> String {
        let trimmed = productDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? planMonthly : trimmed
    }

    static func expirationText(date: Date?) -> String {
        guard let date else { return "—" }
        return Formatters.activityDate.string(from: date)
    }
}
