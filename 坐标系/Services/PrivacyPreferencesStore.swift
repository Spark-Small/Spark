//
//  PrivacyPreferencesStore.swift
//  坐标系
//
//  隐私偏好：设置页写入，搭子卡 / 详情读取。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class PrivacyPreferencesStore {
    static var shared: PrivacyPreferencesStore { AppComposition.privacyPreferencesStore }

    var showDistance: Bool {
        didSet { defaults.set(showDistance, forKey: PrivacyPreferenceKey.showDistance) }
    }

    var showOnline: Bool {
        didSet { defaults.set(showOnline, forKey: PrivacyPreferenceKey.showOnline) }
    }

    var allowInvite: Bool {
        didSet { defaults.set(allowInvite, forKey: PrivacyPreferenceKey.allowInvite) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showDistance = Self.resolvedBool(
            forKey: PrivacyPreferenceKey.showDistance,
            default: true,
            defaults: defaults
        )
        showOnline = Self.resolvedBool(
            forKey: PrivacyPreferenceKey.showOnline,
            default: true,
            defaults: defaults
        )
        allowInvite = Self.resolvedBool(
            forKey: PrivacyPreferenceKey.allowInvite,
            default: true,
            defaults: defaults
        )
    }

    private static func resolvedBool(
        forKey key: String,
        default defaultValue: Bool,
        defaults: UserDefaults
    ) -> Bool {
        if defaults.object(forKey: key) == nil { return defaultValue }
        return defaults.bool(forKey: key)
    }
}
