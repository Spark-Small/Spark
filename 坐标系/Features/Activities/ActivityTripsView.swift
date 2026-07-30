//
//  ActivityTripsView.swift
//  坐标系
//

import SwiftUI

/// 行程页导航：发起人管理
struct ActivityHostManageRoute: Hashable, Identifiable {
    let activityID: Activity.ID
    var id: Activity.ID { activityID }
}

/// 我的行程 / 我的活动：参加 / 发起 / 候补
struct ActivityTripsView: View {
    enum Presentation {
        /// 活动页 Sheet：自带导航栈与「完成」
        case sheet
        /// 「我的」页推入：沿用外层 NavigationStack，不再嵌套一层
        case pushed
    }

    enum Segment: String, CaseIterable, Identifiable {
        case joined = "我参加的"
        case hosted = "我发起的"
        case waitlist = "候补"

        var id: String { rawValue }
    }

    var presentation: Presentation = .sheet
    var initialSegment: Segment = .joined

    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var pendingZoomActivityID: Activity.ID?
    @State private var pendingHostManage: ActivityHostManageRoute?
    @State private var segment: Segment
    @State private var cancelTarget: Activity?
    @State private var cancelRefundTarget: Activity?
    @Namespace private var zoomNamespace

    init(presentation: Presentation = .sheet, initialSegment: Segment = .joined) {
        self.presentation = presentation
        self.initialSegment = initialSegment
        _segment = State(initialValue: initialSegment)
    }

    private var availableSegments: [Segment] {
        var segments: [Segment] = [.joined, .hosted]
        if !model.waitlistActivities.isEmpty || !model.visibleWaitlistPromotions.isEmpty {
            segments.append(.waitlist)
        }
        return segments
    }

    private var items: [Activity] {
        switch segment {
        case .joined: model.joinedActivities.filter { !model.isHost($0) }
        case .hosted: model.hostedActivities
        case .waitlist: model.waitlistActivities
        }
    }

    var body: some View {
        Group {
            if presentation == .sheet {
                NavigationStack(path: $path) {
                    tripsRoot
                }
                .platformSheet(.browser)
            } else {
                tripsRoot
            }
        }
    }

    private var tripsRoot: some View {
        VStack(spacing: 0) {
            Picker("行程", selection: $segment) {
                ForEach(availableSegments) { item in
                    Text(item.rawValue).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)

            if segment == .hosted, !model.hostedActivities.isEmpty {
                hostedManageHeader
            }

            if segment == .waitlist, !model.visibleWaitlistPromotions.isEmpty {
                ActivityWaitlistPromotionSection(
                    activities: model.visibleWaitlistPromotions,
                    onOpen: { openZoom($0) },
                    onDismiss: { model.dismissWaitlistBanner(for: $0) }
                )
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
            }

            if items.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptyIcon,
                    description: Text(emptyDescription)
                )
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(items) { activity in
                        if segment == .hosted {
                            ActivityHostedTripRow(
                                activity: activity,
                                zoomNamespace: zoomNamespace,
                                onManage: { openHostManage(activity.id) }
                            )
                            .listRowInsets(PlatformCardListRow.insets)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3") {
                                    openHostManage(activity.id)
                                }
                                .tint(Color.accentColor)
                                Button("编辑", systemImage: "pencil") {
                                    app.beginEditActivity(activity.id)
                                }
                                .tint(.secondary)
                                Button(ActivityDetailCopy.hostManageCancelActivity, systemImage: "trash", role: .destructive) {
                                    cancelTarget = activity
                                }
                            }
                        } else {
                            ActivityZoomNavigationLink(
                                activity: activity,
                                namespace: zoomNamespace,
                                clip: .card
                            ) {
                                ActivityDiscoverCard(
                                    activity: activity,
                                    isJoined: model.isJoined(activity.id),
                                    enablesOpenTap: false
                                )
                            }
                            .listRowInsets(PlatformCardListRow.insets)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                tripSwipeActions(for: activity)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .safeAreaInset(edge: .bottom) {
                    Color.clear
                        .frame(height: PlatformMetrics.sectionSpacing)
                }
            }
        }
        .background(PlatformSurface.groupedPage)
        .navigationTitle(presentation == .sheet ? "我的行程" : "我的活动")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            model.refreshWaitlistSpotAvailability()
            normalizeSegmentSelection()
        }
        .onChange(of: model.waitlistActivities.count) { _, _ in
            normalizeSegmentSelection()
        }
        .onChange(of: model.visibleWaitlistPromotions.count) { _, _ in
            normalizeSegmentSelection()
        }
        .toolbar {
            if presentation == .sheet {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            if segment == .hosted {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        app.beginComposeActivity()
                        if presentation == .sheet {
                            dismiss()
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("发起活动")
                }
            }
        }
        .activityZoomNavigationDestination(namespace: zoomNamespace)
        .navigationDestination(for: ActivityHostManageRoute.self) { route in
            ActivityHostManageView(activityID: route.activityID)
        }
        .navigationDestination(item: $pendingHostManage) { route in
            ActivityHostManageView(activityID: route.activityID)
        }
        .navigationDestination(item: Binding(
            get: { pendingZoomActivityID.map(PendingActivityZoom.init(id:)) },
            set: { pendingZoomActivityID = $0?.id }
        )) { pending in
            ActivityDetailView(activityID: pending.id)
                .activityZoomNavigationTransition(id: pending.id, in: zoomNamespace)
                .onAppear { model.recordDetailView(pending.id) }
        }
        .alert(
            ActivityDetailCopy.hostManageCancelAlertTitle,
            isPresented: Binding(
                get: { cancelTarget != nil },
                set: { if !$0 { cancelTarget = nil } }
            ),
            presenting: cancelTarget
        ) { activity in
            Button("保留活动", role: .cancel) { cancelTarget = nil }
            Button(ActivityDetailCopy.hostManageCancelActivity, role: .destructive) {
                app.cancelHostedActivity(activity.id)
                cancelTarget = nil
            }
        } message: { activity in
            Text(ActivityDetailCopy.hostManageCancelAlertMessage(title: activity.title))
        }
        .alert(ActivityDetailCopy.cancelWithRefundTitle, isPresented: Binding(
            get: { cancelRefundTarget != nil },
            set: { if !$0 { cancelRefundTarget = nil } }
        )) {
            Button("暂不取消", role: .cancel) {
                cancelRefundTarget = nil
            }
            Button(ActivityDetailCopy.cancelOnly) {
                if let activity = cancelRefundTarget {
                    app.cancelActivityRegistration(activity.id, refundIfPaid: false)
                }
                cancelRefundTarget = nil
            }
            Button(ActivityDetailCopy.cancelWithRefundConfirm, role: .destructive) {
                if let activity = cancelRefundTarget {
                    app.cancelActivityRegistration(activity.id, refundIfPaid: true)
                }
                cancelRefundTarget = nil
            }
        } message: {
            Text(ActivityDetailCopy.cancelWithRefundMessage)
        }
    }

    private var hostedManageHeader: some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            VStack(alignment: .leading) {
                Text(ActivityDetailCopy.hostManageHostedHeader)
                    .font(.subheadline.weight(.semibold))
                Text(ActivityDetailCopy.hostManageHostedSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let snap = CreatorInsightsService.activityOnlySnapshot(activities: model)
            NavigationLink {
                HostInsightsView()
            } label: {
                HStack {
                    Label("主办表现", systemImage: "chart.bar")
                        .font(.subheadline)
                    Spacer()
                    Text("报名 \(snap.totalJoined) · 评论 \(snap.totalActivityComments)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PlatformMetrics.contentInset)
        .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
    }

    private func normalizeSegmentSelection() {
        guard availableSegments.contains(segment) else {
            segment = availableSegments.first ?? .joined
            return
        }
    }

    @ViewBuilder
    private func tripSwipeActions(for activity: Activity) -> some View {
        switch segment {
        case .joined:
            Button(ActivityCardStatus.cancelJoin, systemImage: "ticket") {
                if ActivityPaymentStore.hasPaid(for: activity.id) {
                    cancelRefundTarget = activity
                } else {
                    app.cancelActivityRegistration(activity.id)
                }
            }
            .tint(PlatformStatus.warning)
        case .waitlist:
            Button(ActivityCardStatus.leaveWaitlist, systemImage: "person.badge.minus") {
                _ = model.toggleWaitlist(activity.id)
            }
            .tint(PlatformStatus.warning)
            if activity.isJoinable {
                Button(ActivityCardStatus.join, systemImage: "ticket") {
                    _ = app.quickJoinActivity(activity) { openZoom(activity) }
                }
                .tint(PlatformStatus.success)
            }
        case .hosted:
            EmptyView()
        }
    }

    private func openZoom(_ activity: Activity) {
        if presentation == .sheet {
            path.append(activity.id)
        } else {
            pendingZoomActivityID = activity.id
        }
    }

    private func openHostManage(_ activityID: Activity.ID) {
        let route = ActivityHostManageRoute(activityID: activityID)
        if presentation == .sheet {
            path.append(route)
        } else {
            pendingHostManage = route
        }
    }

    private var emptyTitle: String {
        switch segment {
        case .joined: "还没有参加"
        case .hosted: "还没有发起"
        case .waitlist: "没有候补"
        }
    }

    private var emptyIcon: String {
        switch segment {
        case .joined: "ticket"
        case .hosted: "plus.circle"
        case .waitlist: "person.badge.clock"
        }
    }

    private var emptyDescription: String {
        switch segment {
        case .joined: "看中一场局，点参加就会出现在这里"
        case .hosted: "在活动页发起一场局，会出现在这里"
        case .waitlist: "\(ActivityCardStatus.fullVerbose)时可加入候补，有空位时再参加"
        }
    }
}

private struct PendingActivityZoom: Identifiable, Hashable {
    let id: Activity.ID
}

// MARK: - Favorites（活动域二级页）

/// 活动页「更多」入口：仅收藏的活动。社区分享收藏在社区左上角 Menu。
struct ActivityFavoritesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if model.favoriteActivities.isEmpty {
                    ContentUnavailableView(
                        "还没有收藏活动",
                        systemImage: "bookmark",
                        description: Text("在活动详情里点收藏，想去的局会出现在这里。")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(model.favoriteActivities) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            favoriteRow(activity)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("取消收藏", systemImage: "bookmark.slash") {
                                model.toggleFavorite(activity.id)
                            }
                            .tint(.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle("收藏的活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .platformSheet(.browser)
    }

    private func favoriteRow(_ activity: Activity) -> some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(activity.title)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
                Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(activity.fee)
                        .font(PlatformListTypography.footnote)
                        .foregroundStyle(activity.isFree ? PlatformStatus.success : .secondary)
                    if activity.isPast {
                        Text("已结束")
                            .font(PlatformListTypography.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } icon: {
            Image(systemName: activity.category.systemImage)
                .foregroundStyle(.tint)
        }
    }
}

