//
//  CommunityView+Dynamics.swift
//  坐标系
//
//  动态区：推荐置顶 ≤1（互动通知只在「我的·铃铛」）。
//  「发现作者」不做人轨；靠内容筛选 + 帖卡关注（会话内关注不撕卡）。
//

import SwiftUI
import CoordinateModels

extension CommunityFeedStack {
    var shouldPinRecommended: Bool {
        feedFilter == .all
            && !model.items.isEmpty
            && feedPreferences.recommendationBias != .less
            && recommendedPost != nil
    }

    /// 未锁定时的候选；锁定后关注只改「已关注」，不换置顶帖。
    private var freshRecommendedCandidate: CommunityPost? {
        CommunityFeedFiltering.recommendedPost(
            from: model.items,
            currentUserName: model.currentUserName,
            followedUserNames: app.followedUserNames
        )
    }

    var recommendedPost: CommunityPost? {
        if let id = pinnedRecommendationID,
           let kept = model.items.first(where: { $0.id == id }) {
            return kept
        }
        return freshRecommendedCandidate
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
                .onAppear {
                    if pinnedRecommendationID == nil {
                        pinnedRecommendationID = recommendedPost.id
                    }
                }
            }
        }
    }
}
