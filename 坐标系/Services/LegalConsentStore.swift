//
//  LegalConsentStore.swift
//  坐标系
//
//  用户协议 / 隐私政策同意状态；设置页与登录 Gate 写入。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class LegalConsentStore {
    static var shared: LegalConsentStore { AppComposition.legalConsentStore }
    nonisolated static let acceptedKey = "compliance.legalConsentAccepted"
    nonisolated static let versionKey = "compliance.legalConsentVersion"
    /// 协议文案重大变更时递增，已同意用户需重新确认。
    nonisolated static let currentVersion = 2

    private(set) var hasAccepted: Bool
    private(set) var acceptedVersion: Int

    private let defaults: UserDefaults

    var needsConsent: Bool {
        !hasAccepted || acceptedVersion < Self.currentVersion
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasAccepted = defaults.bool(forKey: Self.acceptedKey)
        acceptedVersion = defaults.integer(forKey: Self.versionKey)
    }

    func accept() {
        hasAccepted = true
        acceptedVersion = Self.currentVersion
        defaults.set(true, forKey: Self.acceptedKey)
        defaults.set(Self.currentVersion, forKey: Self.versionKey)
    }

    func reset() {
        hasAccepted = false
        acceptedVersion = 0
        defaults.removeObject(forKey: Self.acceptedKey)
        defaults.removeObject(forKey: Self.versionKey)
    }
}

/// 非 UI / 启动链读取：与 `LegalConsentStore` 共用 UserDefaults 键。
enum LegalConsentPreference {
    static var needsConsent: Bool {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: LegalConsentStore.acceptedKey) else { return true }
        return defaults.integer(forKey: LegalConsentStore.versionKey) < LegalConsentStore.currentVersion
    }

    static var isAccepted: Bool { !needsConsent }

    static func accept() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: LegalConsentStore.acceptedKey)
        defaults.set(LegalConsentStore.currentVersion, forKey: LegalConsentStore.versionKey)
    }

    static func reset() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LegalConsentStore.acceptedKey)
        defaults.removeObject(forKey: LegalConsentStore.versionKey)
    }
}
