//
//  PrivacyPreferences.swift
//  坐标系
//
//  隐私偏好：设置页写入，搭子卡 / 详情 / 邀约读取。
//

import Foundation
import SwiftUI

enum PrivacyPreferenceKey {
    static let showDistance = "settings.privacy.showDistance"
    static let showOnline = "settings.privacy.showOnline"
    static let allowInvite = "settings.privacy.allowInvite"
}

enum PrivacyPreferences {
    static var showDistance: Bool {
        if UserDefaults.standard.object(forKey: PrivacyPreferenceKey.showDistance) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrivacyPreferenceKey.showDistance)
    }

    static var showOnline: Bool {
        if UserDefaults.standard.object(forKey: PrivacyPreferenceKey.showOnline) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrivacyPreferenceKey.showOnline)
    }

    static var allowInvite: Bool {
        if UserDefaults.standard.object(forKey: PrivacyPreferenceKey.allowInvite) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrivacyPreferenceKey.allowInvite)
    }

    /// 搭子卡次要 meta：按隐私开关过滤距离 / 在线态。
    static func buddyCardMeta(
        distanceText: String,
        statusLine: String,
        extra: [String] = []
    ) -> String {
        var parts = extra
        if showDistance, !distanceText.isEmpty {
            parts.append(distanceText)
        }
        if showOnline, !statusLine.isEmpty {
            parts.append(statusLine)
        } else if !showOnline,
                  !statusLine.isEmpty,
                  statusLine != "在线" {
            // 关闭「在线」时仍可显示「今日活跃」等非实时文案
            parts.append(statusLine)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    static func statusLine(isOnline: Bool, lastActiveText: String) -> String? {
        if isOnline {
            return showOnline ? "在线" : nil
        }
        return lastActiveText.isEmpty ? nil : lastActiveText
    }
}
