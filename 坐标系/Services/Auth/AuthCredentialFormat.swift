//
//  AuthCredentialFormat.swift
//  坐标系
//
//  手机号 / 验证码格式规则（服务层单一来源；UI 经 LoginChrome 转发）。
//

import Foundation

enum AuthCredentialFormat {
    static let codeLength = 6
    static let phoneLength = 11
    static let smsCooldownSeconds = 60

    static func sanitizedPhone(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(phoneLength))
    }

    static func sanitizedCode(_ raw: String) -> String {
        String(raw.filter(\.isNumber).prefix(codeLength))
    }

    static func isValidPhone(_ raw: String) -> Bool {
        let digits = sanitizedPhone(raw)
        return digits.count == phoneLength && digits.hasPrefix("1")
    }

    static func isValidCode(_ raw: String) -> Bool {
        sanitizedCode(raw).count == codeLength
    }
}
