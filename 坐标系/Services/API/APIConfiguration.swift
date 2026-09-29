//
//  APIConfiguration.swift
//  坐标系
//

import CoordinateFeatureFlags
import Foundation
import CoordinateModels

enum APIConfiguration {
    private static let baseURLOverrideKey = "api.baseURLOverride"

    /// 生产须 HTTPS（ATS）。DEBUG 默认同机 Docker；可用 UserDefaults 覆盖。
    static var baseURL: URL {
        #if DEBUG
        if let raw = UserDefaults.standard.string(forKey: baseURLOverrideKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !raw.isEmpty,
           let url = URL(string: raw.hasSuffix("/") ? raw : raw + "/") {
            return url
        }
        return URL(string: localBaseURLString)!
        #else
        // 替换为正式 API 域名后再提审。
        return URL(string: "https://api.zuobiaoxi.com/api/v1/")!
        #endif
    }

    /// 管理后台（浏览器）
    static var adminWebURL: URL {
        #if DEBUG
        URL(string: "http://127.0.0.1:5173/")!
        #else
        URL(string: "https://admin.zuobiaoxi.com/")!
        #endif
    }

    /// 远程活动目录同步；见 `FeatureFlags.useRemoteCatalog`。
    static var useRemoteCatalog: Bool {
        FeatureFlags.useRemoteCatalog
    }

    /// 远程资料同步；见 `FeatureFlags.useRemoteProfile`。
    static var useRemoteProfile: Bool {
        FeatureFlags.useRemoteProfile
    }

    /// 远程消息同步；见 `FeatureFlags.useRemoteMessages`。
    static var useRemoteMessages: Bool {
        FeatureFlags.useRemoteMessages
    }

    /// 远程广场同步；见 `FeatureFlags.useRemoteCommunity`。
    static var useRemoteCommunity: Bool {
        FeatureFlags.useRemoteCommunity
    }

    /// 远程搭子同步；见 `FeatureFlags.useRemoteBuddies`。
    static var useRemoteBuddies: Bool {
        FeatureFlags.useRemoteBuddies
    }

    #if DEBUG
    /// 局域网 / 测试机 HTTP（仅 Debug；须自行保证 ATS 或改用 HTTPS）。
    static let stagingBaseURLString = "http://123.56.118.242/api/v1/"
    static let localBaseURLString = "http://127.0.0.1:8000/api/v1/"

    static var baseURLOverride: String? {
        get { UserDefaults.standard.string(forKey: baseURLOverrideKey) }
        set {
            if let newValue, !newValue.isEmpty {
                UserDefaults.standard.set(newValue, forKey: baseURLOverrideKey)
            } else {
                UserDefaults.standard.removeObject(forKey: baseURLOverrideKey)
            }
        }
    }

    static func setUseRemoteCatalog(_ enabled: Bool) {
        FeatureFlags.setUseRemoteCatalog(enabled)
    }

    static func setUseRemoteProfile(_ enabled: Bool) {
        FeatureFlags.setUseRemoteProfile(enabled)
    }

    static func setUseRemoteMessages(_ enabled: Bool) {
        FeatureFlags.setUseRemoteMessages(enabled)
    }

    static func setUseRemoteCommunity(_ enabled: Bool) {
        FeatureFlags.setUseRemoteCommunity(enabled)
    }

    static func setUseRemoteBuddies(_ enabled: Bool) {
        FeatureFlags.setUseRemoteBuddies(enabled)
    }

    static func setUseRemoteAuth(_ enabled: Bool) {
        FeatureFlags.setUseRemoteAuth(enabled)
    }

    /// D2：活动 / 广场 / 我的读路径 + 远程登录。
    static func enableReadPathRemoteIntegration() {
        FeatureFlags.enableReadPathRemoteIntegration()
    }
    #endif
}
