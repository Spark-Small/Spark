//
//  BuddiesView.swift
//  坐标系
//
//  一页一事：
//  同好 = 情境活动卡 → 兴趣话题 → 状态人卡 → 组织
//  陪玩 = 可预约人 → 语音厅（Discord 频道感）→ 更多陪玩
//

import SwiftUI

struct BuddiesView: View {
    @State private var path = NavigationPath()
    @State private var showCircleDiscover = false
    @State private var showFilterSheet = false
    @State private var weather = GreetingWeatherStore.shared
    @State private var location = LocationService.shared
    @Namespace private var zoomNamespace

    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var model

    /// 陪玩页前半：可预约；后半：更多
    private var paidLeadItems: [DiscoverBuddyItem] {
        Array(model.stageItems.prefix(4))
    }

    private var paidTrailItems: [DiscoverBuddyItem] {
        Array(model.stageItems.dropFirst(4))
    }

    private var situationActivities: [Activity] {
        BuddySituationCatalog.activities(from: activities)
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    if model.isPaidPage {
                        paidBrowse
                    } else {
                        socialBrowse
                    }
                }
                .padding(.bottom, PlatformMetrics.sectionSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(PlatformSurface.groupedPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { buddiesToolbar }
            .task(id: location.observationToken) {
                await weather.refresh()
                model.syncLocatedPlaceName(weather.reading?.placeName)
            }
            .onChange(of: weather.reading?.placeName) { _, place in
                model.syncLocatedPlaceName(place)
            }
            .buddyZoomNavigationDestination(namespace: zoomNamespace)
            .activityZoomSlot("buddies-situation")
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .circleDetailNavigationDestination()
            .navigationDestination(for: VoiceHall.self) { hall in
                BuddyVoiceHallRoomView(hall: hall)
            }
            .navigationDestination(isPresented: $showCircleDiscover) {
                ProfileCircleDiscoverView()
            }
            .sheet(isPresented: $showFilterSheet) {
                BuddyFilterSheet(
                    filter: $model.filter,
                    usesSystemLocation: $model.usesSystemLocation,
                    selectedCityID: $model.selectedCityID,
                    locatedPlaceName: model.locatedPlaceName,
                    needsLocationPermission: weather.status == .needsLocation,
                    onUseSystemLocation: {
                        model.useSystemLocationMode()
                        Task {
                            await weather.refresh(force: true)
                            model.syncLocatedPlaceName(weather.reading?.placeName)
                        }
                    },
                    onOpenSettings: {
                        NotificationService.openSystemSettings()
                    }
                )
            }
            .sheet(item: $model.inviteTarget) { target in
                BuddyInviteSheet(nickname: target.nickname, activities: activities.inviteableActivities) { activity in
                    model.recordInvite(nickname: target.nickname, activity: activity)
                }
            }
            .sheet(item: $model.bookingTarget) { companion in
                BuddyBookingSheet(
                    companion: companion,
                    initialDay: model.bookingInitialDay
                ) { scheduledAt, hours, slotLabel in
                    _ = model.recordBooking(
                        companion: companion,
                        scheduledAt: scheduledAt,
                        hours: hours,
                        slotLabel: slotLabel
                    )
                }
                .onDisappear {
                    if model.bookingTarget == nil {
                        model.bookingInitialDay = nil
                    }
                }
            }
            .platformTransientFeedback($model.toastMessage)
            .buddyOrgJoinChrome(
                buddies: model,
                openCircle: { path.append($0) },
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .sheet(item: Binding(
                get: { model.pendingPaymentBooking },
                set: { if $0 == nil { model.cancelPendingPayment() } }
            )) { record in
                BookingPaymentSheet(
                    record: record,
                    onConfirm: { method in
                        let outcome = model.confirmPayment(record.id, method: method)
                        guard outcome == .success else { return outcome }
                        let greeting =
                            "你好！我想预约 \(Formatters.monthDay.string(from: record.scheduledAt)) "
                            + "\(Formatters.shortTime.string(from: record.scheduledAt)) 开始的 \(record.hours) 小时陪玩，方便确认一下吗？"
                        if let convo = app.startDirectChat(
                            with: record.companionNickname,
                            greeting: greeting
                        ) {
                            app.openMessages(conversationID: convo.id)
                        }
                        return .success
                    },
                    onCancel: {
                        model.cancelPendingPayment()
                    }
                )
            }
            .sheet(item: Binding(
                get: { model.pendingSafetyCheckInBooking },
                set: { if $0 == nil { model.cancelPendingSafetyCheckIn() } }
            )) { record in
                TrustSafetyCheckInSheet(record: record) {
                    model.cancelPendingSafetyCheckIn()
                }
            }
            .platformTabBarHiddenWhenPushed(path.isEmpty && !showCircleDiscover)
            .onAppear { normalizePageMode() }
        }
    }

    // MARK: - 同好

    @ViewBuilder
    private var socialBrowse: some View {
        if !situationActivities.isEmpty {
            BuddySituationRail(
                activities: situationActivities,
                zoomNamespace: zoomNamespace,
                isJoined: { activities.isJoined($0) },
                onJoin: { activity in
                    _ = app.quickJoinActivity(activity) {
                        path.append(ActivityZoomSource(activityID: activity.id, slot: "buddies-situation"))
                    }
                }
            )
        }

        BuddyTopicInterestBar(hobby: Binding(
            get: { model.filter.hobby },
            set: { model.filter.hobby = $0 }
        ))

        if model.stageItems.isEmpty {
            emptyState
        } else {
            DiscoverBrowseSection(
                title: "附近同好",
                subtitle: "一句状态 · 共同兴趣叠在照片上"
            ) {
                BuddyPersonGrid(
                    items: model.stageItems,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onInvite: invite
                )
            }
        }

        if !model.allCircles.isEmpty {
            DiscoverBrowseSection(
                title: "兴趣组织",
                subtitle: "加入即进群，和同好聊起来",
                showsChevron: true,
                onSeeAll: { showCircleDiscover = true }
            ) {
                DiscoverHorizontalRail {
                    ForEach(model.allCircles) { circle in
                        BuddyPosterShelfCard.circle(circle) {
                            path.append(circle)
                        }
                        .platformPosterRailFrame()
                    }
                }
            }
        }
    }

    // MARK: - 陪玩

    @ViewBuilder
    private var paidBrowse: some View {
        if model.stageItems.isEmpty {
            emptyState
        } else {
            DiscoverBrowseSection(
                title: "可预约",
                subtitle: "看档期与价位，点卡进资料"
            ) {
                BuddyPersonGrid(
                    items: paidLeadItems,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onInvite: invite
                )
            }
        }

        if !model.allVoiceHalls.isEmpty {
            BuddyVoiceChannelRail(halls: model.allVoiceHalls) { hall in
                path.append(hall)
            }
        }

        if !paidTrailItems.isEmpty {
            DiscoverBrowseSection(
                title: "更多陪玩",
                subtitle: "继续下滑对比服务"
            ) {
                BuddyPersonGrid(
                    items: paidTrailItems,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onInvite: invite
                )
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var buddiesToolbar: some ToolbarContent {
        @Bindable var model = model

        ToolbarItem(placement: .topBarLeading) {
            Button("筛选", systemImage: "line.3.horizontal.decrease") {
                showFilterSheet = true
            }
            .symbolVariant(model.hasActiveBrowseFilters ? .fill : .none)
            .accessibilityLabel(model.hasActiveBrowseFilters ? "筛选（已启用）" : "筛选")
            .accessibilityHint("打开筛选：地区、性别、距离、兴趣、可约")
            .accessibilityValue(model.browseRegionAccessibilityLabel)
        }

        BuddiesModeSwitchToolbar(kind: $model.filter.kind)
    }

    private func normalizePageMode() {
        if model.filter.kind != .paid {
            model.filter.kind = .free
        }
    }

    private func greet(_ item: DiscoverBuddyItem) {
        if let convo = app.startDirectChat(
            with: item.profile.nickname,
            greeting: "你好，想一起玩吗？"
        ) {
            app.openMessages(conversationID: convo.id)
        }
    }

    private func invite(_ item: DiscoverBuddyItem) {
        switch item {
        case .free(let buddy):
            model.invite(buddy.profile.nickname)
        case .paid(let companion):
            model.book(companion)
        }
    }

    private var emptyState: some View {
        let isPaid = model.isPaidPage
        let filtered = model.hasActiveBrowseFilters
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)
        return ContentUnavailableView {
            Label(
                filtered
                    ? (isPaid ? "没有符合的陪玩" : "没有符合的同好")
                    : (locating
                        ? "正在定位附近的人"
                        : (isPaid ? "附近暂无陪玩" : "附近暂无同好")),
                systemImage: filtered ? "line.3.horizontal.decrease" : "person.2.slash"
            )
        } description: {
            Text(
                filtered
                    ? "试试放宽性别、距离或兴趣，或换个城市看看"
                    : (locating
                        ? "定位完成后会按城市推荐；也可在筛选里指定城市"
                        : (isPaid
                            ? "可以先逛语音厅，或稍后再来"
                            : "可以先去兴趣组织看看"))
            )
        } actions: {
            if filtered {
                PrimaryButton(title: "清除筛选") {
                    model.resetBrowseFilters()
                }
                Button("调整筛选") {
                    showFilterSheet = true
                }
                .buttonStyle(.bordered)
            } else if locating {
                Button("指定城市") {
                    showFilterSheet = true
                }
                .buttonStyle(.borderedProminent)
            } else if isPaid {
                Button("浏览同好") {
                    model.showSocialPage()
                }
                .buttonStyle(.bordered)
            } else {
                Button("浏览兴趣组织") {
                    showCircleDiscover = true
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
        .padding(.horizontal, PlatformMetrics.contentInset)
    }
}

#Preview {
    BuddiesView()
}
