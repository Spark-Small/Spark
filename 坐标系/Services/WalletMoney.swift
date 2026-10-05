//
//  WalletMoney.swift
//  坐标系
//
//  钱包金额展示与解析（分 / 元文案）。
//

import Foundation

enum WalletMoney {
    static func formatted(cents: Int) -> String {
        let yuan = Double(cents) / 100
        if yuan.truncatingRemainder(dividingBy: 1) == 0 {
            return "¥\(Int(yuan))"
        }
        return String(format: "¥%.2f", yuan)
    }

    static func signedFormatted(cents: Int) -> String {
        let absText = formatted(cents: abs(cents))
        if cents > 0 { return "+\(absText)" }
        if cents < 0 { return "-\(absText)" }
        return absText
    }

    /// 从「¥120」「120 元」等文案解析分；失败返回 nil
    static func cents(fromDisplay text: String) -> Int? {
        let pattern = /(\d+(?:\.\d{1,2})?)/
        guard let match = text.firstMatch(of: pattern),
              let yuan = Double(match.1)
        else { return nil }
        return max(Int((yuan * 100).rounded()), 1)
    }

    static func cents(fromYuan yuan: Double) -> Int {
        max(Int((yuan * 100).rounded()), 0)
    }
}
