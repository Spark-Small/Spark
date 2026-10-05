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
    static let activitiesTitle = "我的活动"
    static let rootTitle = "我的"
    static let settingsAccessibilityLabel = "设置"
    /// 根 Form 行：我的陪玩入口文案。
    static let myCompanionEntry = ProfileMyCompanionsCopy.navigationTitle
    /// 根 Form 行：直达我的发帖库。
    static let myPostsEntry = ProfileMyPostsCopy.navigationTitle
    /// 根 Form 行：我的俱乐部（创建入口在此页，不在搭子 Tab）。
    static let myClubsEntry = ProfileMyClubsCopy.navigationTitle
    static let activityInvites = "活动邀约"
    static let servicesSectionTitle = "服务"
    static let librarySectionTitle = "我的内容"
    /// 防欺诈认证文案（个人资料 / 设置·账号）。
    static let photoVerifyRowTitle = "防欺诈认证"
    static let photoVerifyStart = "开始认证"
    static let photoVerifyDone = "已认证"
    static let photoVerifyStartHint = "开始防欺诈认证"
    static let photoVerifyDoneHint = "管理防欺诈认证"
    static let membershipOpenHint = "开通会员"
    static let membershipCenterHint = "打开会员中心"

    static let membershipOpen = "开通会员"
    static let membershipCenter = "会员中心"

    static func photoVerifyTitle(verified: Bool) -> String {
        verified ? photoVerifyDone : photoVerifyStart
    }

    static func photoVerifySystemImage(verified: Bool) -> String {
        verified ? TrustBadgeKind.photoVerified.systemImage : "checkmark.seal"
    }

    static func photoVerifyAccessibilityHint(verified: Bool) -> String {
        verified ? photoVerifyDoneHint : photoVerifyStartHint
    }

    static func membershipTitle(entitled: Bool) -> String {
        entitled ? membershipCenter : membershipOpen
    }

    static func membershipSystemImage(entitled: Bool) -> String {
        entitled ? "checkmark.seal.fill" : "crown.fill"
    }

    static func membershipAccessibilityHint(entitled: Bool) -> String {
        entitled ? membershipCenterHint : membershipOpenHint
    }
    static let walletEntry = "我的钱包"
    static let becomeCompanion = "成为陪玩"

    static let walletTopUp = "充值"

    static let logoutConfirmMessage = "退出后需重新登录才能同步消息与交易记录。"
}

// MARK: - Routes

enum ProfileRoute: Hashable {
    case membership
    case wallet
    case trust
    case activitiesLibrary
    case myPosts
    case myClubs
    case bookingCredentials
    case activityInvites
    case socialGraph(ProfileSocialGraphKind)
    case bookingDetail(BuddyBookingRecord.ID)
    case notifications
    case settings
    /// 产品 tip「去设置」直达隐私页，避免回推设置根成环。
    case privacy
}

struct ProfileRouteDestination: View {
    let route: ProfileRoute

    var body: some View {
        switch route {
        case .membership:
            ProfileMembershipView()
        case .wallet:
            ProfileWalletView()
        case .trust:
            TrustPrivateDashboardView()
        case .activitiesLibrary:
            ProfileMyActivitiesView()
        case .myPosts:
            ProfileMyPostsView()
        case .myClubs:
            ProfileMyClubsView()
        case .bookingCredentials:
            ProfileMyCompanionsRouteView()
        case .activityInvites:
            ProfileActivityInvitesView()
        case .socialGraph(let kind):
            ProfileSocialGraphView(kind: kind)
        case .bookingDetail(let recordID):
            BookingCredentialExpandedView(recordID: recordID)
        case .notifications:
            NotificationsCenterView()
        case .settings:
            ProfileSettingsView()
        case .privacy:
            SettingsPrivacyView()
        }
    }
}

