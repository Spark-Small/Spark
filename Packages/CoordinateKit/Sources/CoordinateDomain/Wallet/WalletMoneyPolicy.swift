//
//  WalletMoneyPolicy.swift
//  CoordinateDomain
//
//  钱包金额与欢迎金策略（与 UI / Store 解耦）。
//

import Foundation

public enum WalletMoneyPolicy: Sendable {
    /// DEBUG 本机演示欢迎金（分）。Release 必须为 0，避免假充值观感。
    public static let debugWelcomeGiftCents: Int = 50_000

    /// Release / 生产欢迎金。
    public static let releaseWelcomeGiftCents: Int = 0

    public static func welcomeGiftCents(isDebugBuild: Bool) -> Int {
        isDebugBuild ? debugWelcomeGiftCents : releaseWelcomeGiftCents
    }

    /// 充值档位下限 / 上限（分）。
    public static let minTopUpCents: Int = 100
    public static let maxTopUpCents: Int = 500_000

    public static func isValidTopUpAmount(_ cents: Int) -> Bool {
        cents >= minTopUpCents && cents <= maxTopUpCents
    }

    /// 允许的远程充值渠道 raw（与 API `channel` 对齐）。
    public static let remoteTopUpChannels: Set<String> = ["wechat", "alipay"]
}
