//
//  CommunityView+Dynamics.swift
//  坐标系
//
//  动态区：推荐置顶 ≤1（互动通知只在「我的·铃铛」）。
//  「发现作者」不做人轨；靠内容筛选 + 帖卡关注。
//

import SwiftUI
import CoordinateModels

extension CommunityFeedStack {
    var shouldPinRecommended: Bool {
        feedFilter == .all
            && !isSearchQueryActive
            && !model.items.isEmpty
            && feedPreferences.recommendationBias != .less
            && recommendedPost != nil
    }

    var recommendedPost: CommunityPost? {
        CommunityFeedFiltering.recommendedPost(
            from: model.items,
            currentUserName: model.currentUserName,
            followedUserNames: app.followedUserNames
        )
    }

    var showsDynamicsRail: Bool {
        shouldPinRecommended
    }

    var showsNotifyBanner: Bool {
        presentation == .tabRoot
            && !feedPreferences.isNotifyBannerDismissed
            && (notificationAuth == .denied || notificationAuth == .notDetermined)
    }

    @ViewBuilder
    var dynamicsSection: some View {
        if shouldPinRecommended, let recommendedPost {
            Section {
                CommunityPostCard(post: recommendedPost, style: .teaser) {
                    feedPreferences.chooseLess()
                }
                .communityFeedRowChrome()
                .accessibilityLabel(
                    "\(CommunityDynamicsCopy.recommendedForYou)，\(recommendedPost.author)"
                )
            }
        }
    }
}
