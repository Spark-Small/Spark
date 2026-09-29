//
//  YouthModeStore.swift
//  坐标系
//
//  青少年模式：设置页写入，商业入口读取。
//

import Foundation
import Observation
import CoordinateModels

@MainActor
@Observable
final class YouthModeStore {
    static var shared: YouthModeStore { AppComposition.youthModeStore }
    nonisolated static let storageKey = "settings.compliance.youthMode"

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Self.storageKey) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isEnabled = defaults.bool(forKey: Self.storageKey)
    }

    func reset() {
        isEnabled = false
        defaults.removeObject(forKey: Self.storageKey)
    }
}

enum YouthModePreference {
    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: YouthModeStore.storageKey)
    }
}
