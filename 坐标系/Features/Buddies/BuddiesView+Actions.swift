//
//  BuddiesView+Actions.swift
//  坐标系
//
//  搭子 Tab：打招呼 / 邀约预约 / pending 深链消费。
//

import SwiftUI
import CoordinateModels

extension BuddiesView {
    func greet(_ item: DiscoverBuddyItem) {
        peerContactRoute = app.openPeerContact(
            with: item.profile.nickname,
            context: .forBuddyItem(item)
        )
    }

    func invite(_ item: DiscoverBuddyItem) {
        switch item {
        case .free(let buddy):
            guard app.requireIdentityAccess(source: .buddyBooking) else { return }
            model.invite(buddy.profile.nickname)
        case .paid(let companion):
            model.book(companion)
        }
    }

    func consumePendingSocialLanding() {
        guard model.pendingShowCircleDiscover else { return }
        model.pendingShowCircleDiscover = false
        model.filter.kind = .clubs
        discoverBrowseScrollRequest += 1
    }

    func consumePendingBuddiesNavigation() {
        guard let route = app.pendingBuddiesRoute else { return }
        app.pendingBuddiesRoute = nil
        switch route {
        case .clubDiscover:
            model.filter.kind = .clubs
            discoverBrowseScrollRequest += 1
        }
    }

    /// 邀约接受 → 活动 Tab 打开关联场次（串联活动模块）
    func consumePendingInviteActivityOpen() {
        guard let activityID = model.presentation.consumePendingOpenActivityAfterInvite() else { return }
        app.openActivity(activityID)
    }
}
