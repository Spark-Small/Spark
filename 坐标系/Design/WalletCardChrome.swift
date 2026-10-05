//
//  WalletCardChrome.swift
//  坐标系
//
//  钱包累计充值等级 + 数字卡 art（App 内 Cash 气质卡面，非系统 Wallet 真卡）。
//

import SwiftUI

/// 累计充值对应的账户等级。
enum WalletBankCardTier: String, CaseIterable, Comparable {
    case classic
    case gold
    case platinum
    case black
    case spectrum

    var rank: Int {
        switch self {
        case .classic: 0
        case .gold: 1
        case .platinum: 2
        case .black: 3
        case .spectrum: 4
        }
    }

    static func < (lhs: Self, rhs: Self) -> Bool { lhs.rank < rhs.rank }

    static func resolve(lifetimeTopUpCents: Int) -> Self {
        switch lifetimeTopUpCents {
        case ..<80_000: .classic
        case ..<300_000: .gold
        case ..<1_000_000: .platinum
        case ..<3_000_000: .black
        default: .spectrum
        }
    }

    var displayName: String {
        switch self {
        case .classic: "普卡"
        case .gold: "金卡"
        case .platinum: "白金卡"
        case .black: "黑卡"
        case .spectrum: "多彩卡"
        }
    }

    var englishName: String {
        switch self {
        case .classic: "Classic"
        case .gold: "Gold"
        case .platinum: "Platinum"
        case .black: "Black"
        case .spectrum: "Spectrum"
        }
    }

    var nextTierHint: String? {
        switch self {
        case .classic: "再充值可升级金卡"
        case .gold: "再充值可升级白金卡"
        case .platinum: "再充值可升级黑卡"
        case .black: "再充值可解锁多彩卡"
        case .spectrum: nil
        }
    }

    /// 用户指定卡面图（Assets `WalletCardArt`，已裁 ID-1）。
    var cardArtAssetName: String { "WalletCardArt" }

    /// 图加载前的中性底。
    var fallbackFill: Color { Color(white: 0.28) }
}

