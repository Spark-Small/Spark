//
//  PrivacyPreferences.swift
//  坐标系
//
//  隐私偏好：设置页经 Store 写入；域逻辑经本枚举读取（同键 UserDefaults）。
//

import Foundation
import SwiftUI
import CoordinateModels

enum PrivacyPreferenceKey {
    static let showDistance = "settings.privacy.showDistance"
    static let showOnline = "settings.privacy.showOnline"
    static let allowInvite = "settings.privacy.allowInvite"
}

enum PrivacyPreferences {
    static var showDistance: Bool {
        resolvedBool(forKey: PrivacyPreferenceKey.showDistance, default: true)
    }

    static var showOnline: Bool {
        resolvedBool(forKey: PrivacyPreferenceKey.showOnline, default: true)
    }

    static var allowInvite: Bool {
        resolvedBool(forKey: PrivacyPreferenceKey.allowInvite, default: true)
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
                  statusLine != BuddyDetailCopy.online {
            parts.append(statusLine)
        }
        return parts.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    static func statusLine(isOnline: Bool, lastActiveText: String) -> String? {
        if isOnline {
            return showOnline ? BuddyDetailCopy.online : nil
        }
        return lastActiveText.isEmpty ? nil : lastActiveText
    }

    private static func resolvedBool(forKey key: String, default defaultValue: Bool) -> Bool {
        if UserDefaults.standard.object(forKey: key) == nil { return defaultValue }
        return UserDefaults.standard.bool(forKey: key)
    }
}
