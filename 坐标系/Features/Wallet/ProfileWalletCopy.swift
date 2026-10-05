//
//  ProfileWalletCopy.swift
//  坐标系
//
//  「钱包」文案：数字卡 + 最近交易 + 账户。
//

import CoordinateFeatureFlags
import Foundation

enum ProfileWalletCopy {
    static let navigationTitle = "我的钱包"
    static let availableBalance = "可用余额"
    static let recentSection = "最近交易"
    static let seeAllLedger = "查看全部"
    static let ledgerTitle = "全部交易"
    static let ledgerSearchPrompt = "搜索交易"

    static let cardBrand = "坐标系"
    /// 卡面副标（非支付网络名）
    static let cardProductMark = "钱包"
    static let cardAccountCaption = "账户"
    static let cardTapHint = "轻点充值"

    static let accountSection = "账户"
    static let defaultPayment = "默认支付"
    static let lifetimeTier = "累计等级"

    static let ledgerEmptyTitle = "暂无交易"
    /// 远程权威时空态只说「暂无」；禁止暗示已全网对账完毕。
    static var ledgerEmptyDescription: String {
        if FeatureFlags.useRemoteWallet {
            return "服务端暂无流水。到账确认后会出现在这里。"
        }
        return "充值与支付会出现在这里。"
    }

    static let alertTitle = "提示"
    static let alertOK = "好的"
}
