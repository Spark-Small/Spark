//
//  CommunityFeedPreferences.swift
//  坐标系
//
//  广场动态区本地偏好：推荐少看、通知关闭横幅。
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

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isNotifyBannerDismissed = defaults.bool(forKey: Key.notifyBannerDismissed)
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
}
