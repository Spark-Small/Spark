//
//  ProfileCredentialFolderViews.swift
//  坐标系
//
//  「我的」活动 / 陪玩凭证：首页预览架 + 活动场次清单（时间分组 · 星标发起 · 只看发起）。
//

import SwiftUI

/// 「我的」首页凭证预览堆张数（活动 / 陪玩一致）。
enum ProfileCredentialPreviewLimits {
    static let shelfPassCount = 4
}

// MARK: - Home shelves

/// 「我的活动」首页凭证预览架。
struct ProfileActivityCredentialsShelf: View {
    var onSeeAll: () -> Void

    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @Environment(\.activityZoomNamespace) private var inheritedZoomNamespace

    @Namespace private var localZoomNamespace

    private var zoomNamespace: Namespace.ID {
        inheritedZoomNamespace ?? localZoomNamespace
    }

    /// 未结束且凭证有效（作废票仅凭证夹可见）。
    private var preview: [Activity] {
        let joined = activities.joinedActivities
            .filter { !activities.isHost($0) && !$0.isPast }
        let hosted = activities.hostedActivities
            .filter { !$0.isPast }
        return Array(
            (joined + hosted)
                .filter {
                    passStore.shouldShowActivityOnPreviewRail(
                        $0,
                        isJoined: activities.isJoined($0.id),
                        isHost: activities.isHost($0)
                    )
                }
                .sorted { $0.date < $1.date }
                .prefix(ProfileCredentialPreviewLimits.shelfPassCount)
        )
    }

    var body: some View {
        DiscoverBrowseSection(title: "我的活动", onSeeAll: onSeeAll) {
            if preview.isEmpty {
                ProfileShelfEmptyState(
                    title: "还没有活动凭证",
                    systemImage: "ticket",
                    description: "参加或发起活动后，这里会以票面展示你的活动凭证。"
                )
            } else {
                WalletPassStack(items: preview, style: .collapsed) { activity in
                    ActivityZoomNavigationLink(
                        activity: activity,
                        namespace: zoomNamespace,
                        clip: .passStrip,
                        intent: .participantPass
                    ) {
                        ProfileActivityCredentialStrip(
                            activity: activity,
                            titleOnly: true
                        )
                        .overlay(alignment: .topTrailing) {
                            if activities.isHost(activity) {
                                ProfileHostedStarMark()
                                    .padding(.top, WalletPassChromePadding.vertical)
                                    .padding(.trailing, WalletPassChromePadding.horizontal)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }
        }
        .activityZoomSlot("profile-activities")
    }
}

/// 「我的陪玩」首页凭证预览架。
struct ProfileBookingCredentialsShelf: View {
    var onSeeAll: () -> Void
    var onOpenBooking: (BuddyBookingRecord.ID) -> Void

    @Environment(BuddiesModel.self) private var buddies
    @Environment(WalletPassStore.self) private var passStore

    private var preview: [BuddyBookingRecord] {
        Array(
            buddies.bookingRecords
                .filter { passStore.shouldShowBookingOnPreviewRail($0) }
                .sorted { $0.scheduledAt < $1.scheduledAt }
                .prefix(ProfileCredentialPreviewLimits.shelfPassCount)
        )
    }

    var body: some View {
        DiscoverBrowseSection(title: "我的陪玩", onSeeAll: onSeeAll) {
            if preview.isEmpty {
                ProfileShelfEmptyState(
                    title: "还没有预约凭证",
                    systemImage: "ticket",
                    description: "支付陪玩预约后，这里会以票面展示你的预约凭证。"
                )
            } else {
                WalletPassStack(items: preview, style: .collapsed) { record in
                    // 与活动 Zoom link 同构：plain Button + 外层导航，避免 NavigationLink 改条宽/条高
                    Button {
                        onOpenBooking(record.id)
                    } label: {
                        ProfileBookingCredentialStrip(
                            record: record,
                            photo: buddies.item(for: record.companionNickname)?.profile.coverPhoto
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }
        }
    }
}

// MARK: - Activity library

/// 我的活动：按时间分组的场次清单；发起带星标；顶栏「只看发起」。
struct ProfileActivityCredentialsView: View {
    @Environment(ActivitiesModel.self) private var activities
    @Environment(WalletPassStore.self) private var passStore
    @Environment(\.activityZoomNamespace) private var inheritedZoomNamespace
    @State private var showHostedOnly = false
    @Namespace private var localZoomNamespace

    private var zoomNamespace: Namespace.ID {
        inheritedZoomNamespace ?? localZoomNamespace
    }

    private var upcomingItems: [Activity] {
        filterHosted(allActiveTickets.filter { !$0.isPast })
            .sorted { $0.date < $1.date }
    }

    private var endedItems: [Activity] {
        filterHosted(allActiveTickets.filter(\.isPast))
            .sorted { $0.date > $1.date }
    }

    private var voidedItems: [Activity] {
        filterHosted(voidedCatalog)
    }

    private var allActiveTickets: [Activity] {
        let joined = activities.joinedActivities
            .filter { !activities.isHost($0) }
            .filter {
                passStore.shouldShowActivityOnPreviewRail(
                    $0,
                    isJoined: true,
                    isHost: false
                )
            }
        let hosted = activities.hostedActivities
            .filter {
                passStore.shouldShowActivityOnPreviewRail(
                    $0,
                    isJoined: activities.isJoined($0.id),
                    isHost: true
                )
            }
        let byID = Dictionary(uniqueKeysWithValues: (joined + hosted).map { ($0.id, $0) })
        return Array(byID.values)
    }

    private var voidedCatalog: [Activity] {
        var byID: [Activity.ID: Activity] = [:]
        for activity in activities.joinedActivities + activities.hostedActivities {
            if isVoidedTicket(activity) {
                byID[activity.id] = activity
            }
        }
        for pass in passStore.passes where pass.voided && pass.style == .eventTicket {
            guard let related = pass.relatedID else { continue }
            if let activity = activities.activity(id: related) {
                byID[activity.id] = activity
            } else if let order = ActivityPaymentStore.order(id: related),
                      let activity = activities.activity(id: order.activityID) {
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
                        emptyTitle,
                        systemImage: showHostedOnly ? "star" : "ticket",
                        description: Text(emptyDescription)
                    )
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
        .listStyle(.insetGrouped)
        .listSectionSpacing(.compact)
        .navigationTitle("我的活动")
        .navigationBarTitleDisplayMode(.inline)
        .platformSecondaryPage()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ProfileHostedStarFilterButton(showHostedOnly: $showHostedOnly)
            }
        }
        .activityZoomSlot("profile-activity-library")
        .activityZoomNavigationDestinationIfNeeded(fallback: localZoomNamespace)
        .onAppear(perform: backfillActivePasses)
    }

    private var emptyTitle: String {
        showHostedOnly ? "还没有发起的活动" : "还没有活动"
    }

    private var emptyDescription: String {
        showHostedOnly
            ? "发起一场活动后会出现在这里。点右上角「全部」可查看参加的场次。"
            : "去活动页找一场局参加，或发起你的第一场。"
    }

    private func filterHosted(_ items: [Activity]) -> [Activity] {
        guard showHostedOnly else { return items }
        return items.filter { activities.isHost($0) }
    }

    @ViewBuilder
    private func credentialRow(_ activity: Activity, voided: Bool) -> some View {
        let hosted = activities.isHost(activity)
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
            .overlay(alignment: .topTrailing) {
                if hosted {
                    ProfileHostedStarMark()
                        .padding(.top, WalletPassChromePadding.vertical)
                        .padding(.trailing, WalletPassChromePadding.horizontal)
                }
            }
        }
        .contextMenu {
            if !voided,
               passStore.activityPass(for: activity, activeOnly: true) == nil,
               activities.isJoined(activity.id) || hosted {
                Button("补发", systemImage: "ticket") {
                    reissue(activity)
                }
            }
        }
        .platformWalletPassCredentialRow()
        .accessibilityHint(hosted ? "我发起的" : "")
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
        for activity in allActiveTickets
        where activities.isJoined(activity.id) || activities.isHost(activity) {
            guard passStore.activityPass(for: activity, activeOnly: true) == nil else { continue }
            reissue(activity)
        }
    }
}



// 陪玩预约凭证夹（有效 / 已作废）— 嵌在「我的陪玩」List 的 bookings 分段内。
struct ProfileBookingCredentialsSection: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(WalletPassStore.self) private var passStore

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

    private var awaitingPaymentRecords: [BuddyBookingRecord] {
        buddies.bookingRecords.filter {
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
                Text("支付成功后自动签发；退款或取消后作废，仅在下方「已作废」中保留。点开长条票面可展开凭证，长按可补发或删除。")
            }

            if !awaitingPaymentRecords.isEmpty {
                Section {
                    ForEach(awaitingPaymentRecords) { record in
                        NavigationLink {
                            BookingCredentialExpandedView(recordID: record.id)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.companionNickname)
                                    .font(.body.weight(.semibold))
                                Text("\(record.statusLabel) · 支付后生成预约凭证")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("待支付 / 待确认")
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
                voided: voided
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
