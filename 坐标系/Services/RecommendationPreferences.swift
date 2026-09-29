//
//  RecommendationPreferences.swift
//  坐标系
//
//  推荐 / 匹配算法可调参数（演示级 UserDefaults 持久化）。
//

import Foundation
import CoordinateModels

enum RecommendationConfig {
    /// 「附近」阈值（km）
    static var nearbyKM: Double {
        get {
            let v = UserDefaults.standard.double(forKey: Keys.nearbyKM)
            return v > 0 ? v : 3
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.nearbyKM) }
    }

    /// 「即将开始」窗口（小时）
    static var startingSoonHours: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: Keys.startingSoonHours)
            return v > 0 ? v : 48
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.startingSoonHours) }
    }

    private enum Keys {
        static let nearbyKM = "reco.nearbyKM"
        static let startingSoonHours = "reco.startingSoonHours"
    }
}

enum MatchWeights {
    static var sharedHobby: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: Keys.sharedHobby)
            return v > 0 ? v : 30
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.sharedHobby) }
    }

    static var availableBonus: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: Keys.availableBonus)
            return v > 0 ? v : 20
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.availableBonus) }
    }

    static var onlineBonus: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: Keys.onlineBonus)
            return v > 0 ? v : 10
        }
        set { UserDefaults.standard.set(newValue, forKey: Keys.onlineBonus) }
    }

    private enum Keys {
        static let sharedHobby = "match.sharedHobby"
        static let availableBonus = "match.availableBonus"
        static let onlineBonus = "match.onlineBonus"
    }
}
