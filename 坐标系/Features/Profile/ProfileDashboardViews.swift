//
//  ProfileDashboardViews.swift
//  坐标系
//
//  「我的」文案，以及最近浏览横滑轨与二级列表。
//

import SwiftUI

// MARK: - Copy

enum ProfileDashboardCopy {
    static let ordersTitle = "我的订单"
    static let activitiesTitle = "我的活动"
    static let rootTitle = "我的"
    static let activityHosted = "我发起的"
    static let activityJoined = "我报名的"
    static let activityFavorites = "我收藏的"
    static let activityHistory = "浏览记录"
    static let bookingCredentials = "陪玩预约"
    static let activityInvites = "活动邀约"

    static let membershipOpen = "开通会员"
    static let membershipCenter = "会员中心"
    static let walletEntry = "我的钱包"
    static let becomeCompanion = "成为陪玩"
    static let guestHint = "访客 · 创建账号解锁交易与资料"
    static let trustEntry = "我的认证"
    static let reputationSectionTitle = "我的信誉"

    static let walletCoupons = "优惠券"
    static let walletPoints = "积分"
    static let walletTopUp = "充值"
    static let walletWithdraw = "提现"
    static let walletLedger = "账单明细"
    static let walletInvoice = "发票中心"

    static let recentBrowseTitle = "最近浏览"
    static let recentBrowseClear = "清空"
    static let recentBrowseEmpty = "还没有浏览记录"
    static let recentBrowseListTitle = "浏览记录"
    static let recentBrowseEmptyHint = "打开活动详情后会自动记录。"

    static let demoWithdraw = "本地演示暂不支持提现，正式版将接入实名与银行卡。"
    static let demoInvoice = "本地演示暂不支持开票，正式版将提供电子发票中心。"

    static let logout = "退出登录"
    static let logoutConfirmTitle = "退出登录？"
    static let logoutConfirmMessage = "退出后需重新登录才能同步订单与消息。"
}

// MARK: - Routes

enum ProfileRoute: Hashable {
    case membership
    case wallet
    case becomeCompanion
    case orders(ProfileOrderShortcutFilter?)
    case trust
    case hostedActivities
    case joinedActivities
    case favoriteActivities
    case browseHistory
    case bookingCredentials
    case activityInvites
    case bookingDetail(BuddyBookingRecord.ID)
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
        case .hostedActivities:
            ProfilePublishedLibraryView(initialSegment: .activities)
        case .joinedActivities:
            ProfileActivityCredentialsView()
        case .favoriteActivities:
            ProfileFavoriteActivitiesLibraryView()
        case .browseHistory:
            ProfileRecentBrowseListView()
        case .bookingCredentials:
            ProfileBookingCredentialsView()
        case .activityInvites:
            ProfileActivityInvitesView()
        case .bookingDetail(let recordID):
            BookingCredentialExpandedView(recordID: recordID)
        }
    }
}

// MARK: - Recent browse shelf

/// 「我的」最近浏览：发现页同款横滑轨，而非 Settings 式长列表。
struct ProfileRecentBrowseShelf: View {
    let records: [ProfileRecentBrowseRecord]
    var zoomNamespace: Namespace.ID
    var onSeeAll: (() -> Void)?

    @Environment(ActivitiesModel.self) private var activities

    private var previewRecords: [ProfileRecentBrowseRecord] {
        Array(records.prefix(8))
    }

    var body: some View {
        DiscoverBrowseSection(
            title: ProfileDashboardCopy.recentBrowseTitle,
            onSeeAll: previewRecords.isEmpty ? nil : onSeeAll
        ) {
            if previewRecords.isEmpty {
                Text(ProfileDashboardCopy.recentBrowseEmpty)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlatformMetrics.contentInset)
            } else {
                DiscoverHorizontalRail {
                    ForEach(previewRecords) { record in
                        if let activity = activities.activity(id: record.activityID) {
                            PlatformContinueCard(
                                activityID: activity.id,
                                zoomNamespace: zoomNamespace,
                                photo: activity.coverPhoto,
                                title: activity.title,
                                timeLine: Formatters.activityEventTime(from: activity.date),
                                metaLine: Formatters.conversationListTime(from: record.viewedAt),
                                isJoined: activities.isJoined(activity.id),
                                isFull: activity.isFull
                            )
                            .platformContinueRailFrame()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Recent browse list

struct ProfileRecentBrowseListView: View {
    @Environment(ActivitiesModel.self) private var activities
    @State private var records = ProfileRecentBrowseStore.shared.items()

    var body: some View {
        List {
            if records.isEmpty {
                ContentUnavailableView(
                    ProfileDashboardCopy.recentBrowseEmpty,
                    systemImage: "clock.arrow.circlepath",
                    description: Text(ProfileDashboardCopy.recentBrowseEmptyHint)
                )
            } else {
                ForEach(records) { record in
                    if let activity = activities.activity(id: record.activityID) {
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            LabeledContent(record.title) {
                                Text(Formatters.conversationListTime(from: record.viewedAt))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(ProfileDashboardCopy.recentBrowseListTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !records.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(ProfileDashboardCopy.recentBrowseClear, role: .destructive) {
                        ProfileRecentBrowseStore.shared.clear()
                        records = []
                    }
                }
            }
        }
    }
}
