//
//  ProfileCredentialFolderViews.swift
//  坐标系
//
//  「我的」活动 / 陪玩凭证：场次清单与陪玩预约分区。
//

import SwiftUI

// MARK: - Activity library

/// 「我报名的」：仅参加场次凭证（发起活动见「我发起的」）。
struct ProfileActivityCredentialsView: View {
    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @Environment(AppModel.self) private var app
    @Environment(\.activityZoomNamespace) private var inheritedZoomNamespace
    @Namespace private var localZoomNamespace

    private var zoomNamespace: Namespace.ID {
        inheritedZoomNamespace ?? localZoomNamespace
    }

    private var upcomingItems: [Activity] {
        joinedTickets.filter { !$0.isPast }
            .sorted { $0.date < $1.date }
    }

    private var endedItems: [Activity] {
        joinedTickets.filter(\.isPast)
            .sorted { $0.date > $1.date }
    }

    private var voidedItems: [Activity] {
        voidedCatalog
    }

    private var joinedTickets: [Activity] {
        activities.joinedActivities
            .filter { !activities.isHost($0) }
            .filter {
                passStore.shouldShowActivityOnPreviewRail(
                    $0,
                    isJoined: true,
                    isHost: false
                )
            }
    }

    private var voidedCatalog: [Activity] {
        var byID: [Activity.ID: Activity] = [:]
        for activity in activities.joinedActivities where !activities.isHost(activity) {
            if isVoidedTicket(activity) {
                byID[activity.id] = activity
            }
        }
        for pass in passStore.passes where pass.voided && pass.style == .eventTicket {
            guard let related = pass.relatedID else { continue }
            if let activity = activities.activity(id: related),
               activities.isJoined(activity.id),
               !activities.isHost(activity) {
                byID[activity.id] = activity
            } else if let order = ActivityPaymentStore.order(id: related),
                      let activity = activities.activity(id: order.activityID),
                      activities.isJoined(activity.id),
                      !activities.isHost(activity) {
                byID[activity.id] = activity
            }
        }
        return byID.values
            .filter(isVoidedTicket)
            .sorted { $0.date > $1.date }
    }

    private var hasAnyContent: Bool {
        !upcomingItems.isEmpty || !endedItems.isEmpty || !voidedItems.isEmpty
    }

    var body: some View {
        List {
            if !hasAnyContent {
                Section {
                    ContentUnavailableView(
                        "还没有报名的活动",
                        systemImage: "ticket",
                        description: Text("去活动页找一场局参加，凭证会出现在这里。")
                    )
                    .listRowBackground(Color.clear)

                    Button("去发现活动") {
                        app.selectedTab = .activities
                    }
                    .activityPrimaryCTA(controlSize: .large)
                    .buttonSizing(.flexible)
                    .listRowBackground(Color.clear)
                }
            } else {
                if !upcomingItems.isEmpty {
                    Section {
                        ForEach(upcomingItems) { activity in
                            credentialRow(activity, voided: false)
                        }
                    } header: {
                        Text("即将开始")
                    }
                }

                if !endedItems.isEmpty {
                    Section {
                        ForEach(endedItems) { activity in
                            credentialRow(activity, voided: false)
                        }
                    } header: {
                        Text("已结束")
                    }
                }

                if !voidedItems.isEmpty {
                    Section {
                        ForEach(voidedItems) { activity in
                            credentialRow(activity, voided: true)
                        }
                    } header: {
                        Text("已作废")
                    }
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.activityJoined)
        .navigationBarTitleDisplayMode(.inline)
        .activityZoomSlot("profile-activity-library")
        .activityZoomNavigationDestinationIfNeeded(fallback: localZoomNamespace)
        .onAppear(perform: backfillActivePasses)
    }

    @ViewBuilder
    private func credentialRow(_ activity: Activity, voided: Bool) -> some View {
        ActivityZoomNavigationLink(
            activity: activity,
            namespace: zoomNamespace,
            clip: .passStrip,
            intent: .participantPass
        ) {
            ProfileActivityCredentialStrip(
                activity: activity,
                voided: voided
            )
        }
        .contextMenu {
            if !voided,
               passStore.activityPass(for: activity, activeOnly: true) == nil,
               activities.isJoined(activity.id) {
                Button("补发", systemImage: "ticket") {
                    reissue(activity)
                }
            }
        }
        .platformWalletPassCredentialRow()
    }

    private func isVoidedTicket(_ activity: Activity) -> Bool {
        passStore.activityPass(for: activity, activeOnly: true) == nil
            && passStore.activityPass(for: activity, activeOnly: false)?.voided == true
    }

    private func reissue(_ activity: Activity) {
        if let order = ActivityPaymentStore.paidOrder(for: activity.id) {
            _ = passStore.issueActivityTicket(order: order, activity: activity)
        } else {
            _ = passStore.issueActivityAttendanceTicket(for: activity)
        }
    }

    private func backfillActivePasses() {
        for activity in joinedTickets where activities.isJoined(activity.id) {
            guard passStore.activityPass(for: activity, activeOnly: true) == nil else { continue }
            reissue(activity)
        }
    }
}

// MARK: - Booking credentials

// 陪玩预约凭证夹（有效 / 已作废）— 「我的 → 陪玩预约」；待支付走「我的订单」。
struct ProfileBookingCredentialsSection: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(WalletPassStore.self) private var passStore
    @Environment(AppModel.self) private var app
    @State private var peerContactRoute: PeerContactRoute?

    private var activeRecords: [BuddyBookingRecord] {
        buddies.bookingRecords.filter { passStore.shouldShowBookingOnPreviewRail($0) }
    }

    private var voidedRecords: [BuddyBookingRecord] {
        buddies.bookingRecords.filter { record in
            if passStore.bookingPass(for: record.id, activeOnly: false)?.voided == true {
                return true
            }
            return record.status == .refunded || record.status == .cancelled
        }
    }

    private var hasPendingOrders: Bool {
        buddies.bookingRecords.contains {
            $0.status == .pendingConfirm || $0.status == .awaitingPayment
        }
    }

    var body: some View {
        Group {
            Section {
                if activeRecords.isEmpty {
                    ContentUnavailableView(
                        "还没有预约凭证",
                        systemImage: "ticket",
                        description: Text("支付陪玩预约后，凭证会出现在这里。")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    bookingPassStackRow(activeRecords, voided: false)
                }
            } footer: {
                if hasPendingOrders {
                    Text("\(ProfileDashboardCopy.ordersPendingBookingFooter) 支付成功后自动签发；退款或取消后作废，仅在下方「已作废」中保留。点开长条票面可展开凭证，长按可补发或删除。")
                } else {
                    Text("支付成功后自动签发；退款或取消后作废，仅在下方「已作废」中保留。点开长条票面可展开凭证，长按可补发或删除。")
                }
            }

            if !voidedRecords.isEmpty {
                Section {
                    bookingPassStackRow(voidedRecords, voided: true)
                } header: {
                    Text("已作废")
                } footer: {
                    Text("作废票不出现在「我的」预览轨，仅在此查阅。")
                }
            }
        }
        .peerContactDestination(route: $peerContactRoute)
        .onAppear {
            for record in activeRecords {
                _ = passStore.issueBookingTicket(for: record)
            }
        }
    }

    private func bookingPassStackRow(_ records: [BuddyBookingRecord], voided: Bool) -> some View {
        WalletPassStack(items: records, style: .scrolling) { record in
            bookingStackCard(record, voided: voided)
        }
        .platformWalletPassCredentialRow()
    }

    @ViewBuilder
    private func bookingStackCard(_ record: BuddyBookingRecord, voided: Bool) -> some View {
        NavigationLink {
            BookingCredentialExpandedView(recordID: record.id)
        } label: {
            ProfileBookingCredentialStrip(
                record: record,
                photo: buddies.item(for: record.companionNickname)?.profile.coverPhoto,
                statusOverride: voided ? "已作废" : nil,
                voided: voided,
                onRequestMessage: {
                    peerContactRoute = app.openPeerContact(
                        with: record.companionNickname,
                        context: .forBooking(record)
                    )
                }
            )
        }
        .buttonStyle(.plain)
        .navigationLinkIndicatorVisibility(.hidden)
        .contextMenu {
            Button("删除", systemImage: "trash", role: .destructive) {
                buddies.deleteBooking(record.id)
            }
            if record.canPay {
                Button("去支付", systemImage: "yensign.circle") {
                    buddies.beginPayment(record.id)
                }
            }
            if !voided,
               passStore.bookingPass(for: record.id, activeOnly: true) == nil,
               record.status == .paid || record.status == .inProgress || record.status == .completed {
                Button("补发", systemImage: "ticket") {
                    _ = passStore.issueBookingTicket(for: record)
                }
            }
        }
    }
}
