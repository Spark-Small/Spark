//
//  ProfileDashboardViews.swift
//  坐标系
//
//  「我的」文案、路由与二级 List chrome。
//

import SwiftUI
import CoordinateModels

// MARK: - Copy

enum ProfileDashboardCopy {
    static let ordersTitle = "我的订单"
    static let activitiesTitle = "我的活动"
    static let rootTitle = "我的"
    static let settingsAccessibilityLabel = "设置"
    static let notificationsAccessibilityLabel = "通知"
    static let communityLibraryTitle = "广场内容"
    static let communityBookmarks = "收藏的分享"
    static let communityLiked = "赞过的"
    static let communityMyPosts = "我的分享"
    static let communityReposts = "我的转发"
    static let communityGuidelines = "社区公约"
    static let activityHosted = "我发起的"
    static let activityJoined = "我报名的"
    static let activityFavorites = "我的收藏" // 根列表不挂；详情「更多」→ 收藏库
    static let bookingCredentials = "陪玩预约"
    static let activityInvites = "活动邀约"
    static let activitiesLibraryTitle = "活动与行程"
    static let activitiesLibraryFooter = "发起、报名与邀约都在这里。"
    static let attentionSectionTitle = "待办"
    static let servicesSectionTitle = "服务"
    static let librarySectionTitle = "我的内容"
    static let trustBadgeAccessibilityHint = "打开我的认证"
    static let myClubsTitle = "我的俱乐部"
    static let myClubsHosted = "我创建的"
    static let myClubsJoined = "已加入"
    static let myClubsEmpty = "还没有加入俱乐部"
    static let myClubsEmptyHint = "可在搭子页发现同城俱乐部，或在此创建自己的。"
    static let createClub = "创建俱乐部"
    static let createClubHint = "自定义名称，创建本地俱乐部"

    static let membershipOpen = "开通会员"
    static let membershipCenter = "会员中心"
    static let walletEntry = "我的钱包"
    static let becomeCompanion = "成为陪玩"
    static let guestHint = "访客 · 创建账号解锁交易与资料"
    static let trustEntry = "我的认证"

    static let walletCoupons = "优惠券"
    static let walletPoints = "积分"
    static let walletTopUp = "充值"
    static let walletWithdraw = "提现"
    static let walletLedger = "账单明细"
    static let walletInvoice = "发票中心"

    static let demoWithdraw = "本地演示暂不支持提现，正式版将接入实名与银行卡。"
    static let demoInvoice = "本地演示暂不支持开票，正式版将提供电子发票中心。"

    static let logout = "退出登录"
    static let logoutConfirmTitle = "退出登录？"
    static let logoutConfirmMessage = "退出后需重新登录才能同步订单与消息。"
    static let ordersPendingBookingFooter = "有待支付或待确认的预约，请到「我的订单」处理。"
}

// MARK: - Routes

enum ProfileRoute: Hashable {
    case membership
    case wallet
    case becomeCompanion
    case orders(ProfileOrderShortcutFilter?)
    case trust
    case activitiesLibrary
    case communityLibrary
    case hostedActivities
    case joinedActivities
    case favoriteActivities
    case bookingCredentials
    case activityInvites
    case myClubs
    case bookingDetail(BuddyBookingRecord.ID)
    case notifications
}

struct ProfileRouteDestination: View {
    let route: ProfileRoute

    var body: some View {
        switch route {
        case .membership:
            ProfileMembershipView()
        case .wallet:
            ProfileWalletView()
        case .becomeCompanion:
            ProfileBecomeCompanionView()
        case .orders(let shortcut):
            ProfileOrdersView(initialShortcut: shortcut)
        case .trust:
            TrustPrivateDashboardView()
        case .activitiesLibrary:
            ProfileActivitiesLibraryHubView()
        case .communityLibrary:
            ProfileCommunityLibraryHubView()
        case .hostedActivities:
            ProfilePublishedLibraryView(initialSegment: .activities)
        case .joinedActivities:
            ProfileActivityCredentialsView()
        case .favoriteActivities:
            ProfileFavoriteActivitiesLibraryView()
        case .bookingCredentials:
            ProfileBookingCredentialsView()
        case .activityInvites:
            ProfileActivityInvitesView()
        case .myClubs:
            ProfileMyClubsView()
        case .bookingDetail(let recordID):
            BookingCredentialExpandedView(recordID: recordID)
        case .notifications:
            NotificationsCenterView()
        }
    }
}

// MARK: - Secondary list chrome

extension View {
    /// 「我的」二级页：insetGrouped + 紧凑分区（与订单 / 凭证夹一致）。
    func profileSecondaryListChrome() -> some View {
        listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
    }
}
