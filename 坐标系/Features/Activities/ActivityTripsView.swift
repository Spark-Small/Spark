//
//  ActivityTripsView.swift
//  坐标系
//

import SwiftUI

/// 行程页导航：发起人管理
struct ActivityHostManageRoute: Hashable {
    let activityID: Activity.ID
}

/// 我的行程：参加 / 发起 / 收藏 — 服务「参加」导向的回访
struct ActivityTripsView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var path = NavigationPath()
    @State private var segment: Segment = .joined
    @State private var cancelTarget: Activity?
    @State private var cancelRefundTarget: Activity?
    @Namespace private var zoomNamespace

    private enum Segment: String, CaseIterable, Identifiable {
        case joined = "我参加的"
        case hosted = "我发起的"
        case favorites = "收藏"
        case waitlist = "候补"

        var id: String { rawValue }
    }

    private var availableSegments: [Segment] {
        var segments: [Segment] = [.joined, .hosted, .favorites]
        if !model.waitlistActivities.isEmpty || !model.visibleWaitlistPromotions.isEmpty {
            segments.append(.waitlist)
        }
        return segments
    }

    private var items: [Activity] {
        switch segment {
        case .joined: model.joinedActivities.filter { !model.isHost($0) }
        case .hosted: model.hostedActivities
        case .favorites: model.favoriteActivities
        case .waitlist: model.waitlistActivities
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
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
                                    onManage: { path.append(ActivityHostManageRoute(activityID: activity.id)) }
                                )
                                .listRowInsets(PlatformCardListRow.insets)
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(ActivityDetailCopy.hostManageTitle, systemImage: "slider.horizontal.3") {
                                        path.append(ActivityHostManageRoute(activityID: activity.id))
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
            .navigationTitle("我的行程")
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
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                if segment == .hosted {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            dismiss()
                            model.editingActivityID = nil
                            model.isComposing = true
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
        .platformSheet(.browser)
    }

    private var hostedManageHeader: some View {
        VStack(alignment: .leading) {
            Text(ActivityDetailCopy.hostManageHostedHeader)
                .font(.subheadline.weight(.semibold))
            Text(ActivityDetailCopy.hostManageHostedSubtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
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
        case .favorites:
            Button(ActivityCardStatus.unfavorite, systemImage: "bookmark.slash") {
                model.toggleFavorite(activity.id)
            }
            .tint(.secondary)
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
        path.append(activity.id)
    }

    private var emptyTitle: String {
        switch segment {
        case .joined: "还没有参加"
        case .hosted: "还没有发起"
        case .favorites: "还没有收藏"
        case .waitlist: "没有候补"
        }
    }

    private var emptyIcon: String {
        switch segment {
        case .joined: "ticket"
        case .hosted: "plus.circle"
        case .favorites: "bookmark"
        case .waitlist: "person.badge.clock"
        }
    }

    private var emptyDescription: String {
        switch segment {
        case .joined: "看中一场局，点参加就会出现在这里"
        case .hosted: "右上角发起活动，组织一场局"
        case .favorites: "先收藏感兴趣的活动，稍后参加"
        case .waitlist: "\(ActivityCardStatus.fullVerbose)时可加入候补，有空位时再参加"
        }
    }
}
