//
//  CommunityFeedPreferences.swift
//  坐标系
//
//  广场动态区本地偏好：推荐少看、通知关闭横幅、搜索历史。
//

import Foundation
import Observation

enum CommunityFeedPreferenceBias: String, Codable, Sendable {
    case less
}

@MainActor
@Observable
final class CommunityFeedPreferences {
    private enum Key {
        static let bias = "community.feed.recommendation.bias"
        static let notifyBannerDismissed = "community.feed.notifyBanner.dismissed"
        static let recentSearches = "community.feed.recentSearches"
        static let maxRecentSearches = 5
    }

    private let defaults: UserDefaults

    /// `less` 时隐藏推荐置顶；未设置则展示。
    var recommendationBias: CommunityFeedPreferenceBias? {
        didSet {
            if let recommendationBias {
                defaults.set(recommendationBias.rawValue, forKey: Key.bias)
            } else {
                defaults.removeObject(forKey: Key.bias)
            }
        }
    }

    var isNotifyBannerDismissed: Bool {
        didSet { defaults.set(isNotifyBannerDismissed, forKey: Key.notifyBannerDismissed) }
    }

    private(set) var recentSearches: [String] {
        didSet { defaults.set(recentSearches, forKey: Key.recentSearches) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isNotifyBannerDismissed = defaults.bool(forKey: Key.notifyBannerDismissed)
        recentSearches = defaults.stringArray(forKey: Key.recentSearches) ?? []
        if let raw = defaults.string(forKey: Key.bias) {
            recommendationBias = CommunityFeedPreferenceBias(rawValue: raw)
        } else {
            recommendationBias = nil
        }
    }

    func chooseLess() {
        recommendationBias = .less
    }

    func dismissNotifyBanner() {
        isNotifyBannerDismissed = true
    }

    func rememberSearch(_ raw: String) {
        let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        var next = recentSearches.filter { $0.caseInsensitiveCompare(query) != .orderedSame }
        next.insert(query, at: 0)
        if next.count > Key.maxRecentSearches {
            next = Array(next.prefix(Key.maxRecentSearches))
        }
        recentSearches = next
    }
}
