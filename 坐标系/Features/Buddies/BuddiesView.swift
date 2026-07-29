//
//  BuddiesView.swift
//  坐标系
//
//  一页一事：同好（精选 Hero + 双列网格 + 组织）| 陪玩（精选 Hero + 双列网格 + 语音厅）。
//

import SwiftUI

struct BuddiesView: View {
    @State private var path = NavigationPath()
    @State private var showCircleDiscover = false
    @State private var showFilterSheet = false
    @State private var focusedBuddyID: DiscoverBuddyItem.ID?
    @State private var weather = GreetingWeatherStore.shared
    @State private var location = LocationService.shared
    @Namespace private var zoomNamespace

    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var model

    /// 网格里不重复展示当前 Hero 焦点人
    private var gridItems: [DiscoverBuddyItem] {
        guard let focusedBuddyID else { return model.stageItems }
        return model.stageItems.filter { $0.id != focusedBuddyID }
    }

    var body: some View {
        @Bindable var model = model

        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    personBrowse
                    secondaryShelf
                }
                .padding(.bottom, PlatformMetrics.sectionSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollEdgeEffectStyle(.soft, for: .top)
            .background(PlatformSurface.groupedPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { buddiesToolbar }
            .ignoresSafeArea(edges: model.stageItems.isEmpty ? [] : .top)
            .task(id: location.observationToken) {
                await weather.refresh()
                model.syncLocatedPlaceName(weather.reading?.placeName)
            }
            .onChange(of: weather.reading?.placeName) { _, place in
                model.syncLocatedPlaceName(place)
            }
            .onChange(of: model.isPaidPage) { _, _ in
                focusedBuddyID = model.stageItems.first?.id
            }
            .onChange(of: model.stageItems.map(\.id)) { _, ids in
                if let focusedBuddyID, ids.contains(focusedBuddyID) { return }
                focusedBuddyID = ids.first
            }
            .navigationDestination(for: DiscoverBuddyItem.self) { item in
                BuddyDetailRouteView(item: item)
                    .buddyZoomNavigationTransition(id: item.id, in: zoomNamespace)
            }
            .navigationDestination(for: Activity.self) { activity in
                ActivityDetailView(activity: activity)
            }
            .navigationDestination(for: InterestCircle.self) { circle in
                ProfileCircleDetailView(circle: circle)
            }
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
                BuddyBookingSheet(companion: companion) { scheduledAt, hours, slotLabel in
                    _ = model.recordBooking(
                        companion: companion,
                        scheduledAt: scheduledAt,
                        hours: hours,
                        slotLabel: slotLabel
                    )
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
                    onConfirm: {
                        model.confirmPayment(record.id)
                        let greeting =
                            "你好！我想预约 \(Formatters.monthDay.string(from: record.scheduledAt)) "
                            + "\(Formatters.shortTime.string(from: record.scheduledAt)) 开始的 \(record.hours) 小时陪玩，方便确认一下吗？"
                        if let convo = app.startDirectChat(
                            with: record.companionNickname,
                            greeting: greeting
                        ) {
                            app.openMessages(conversationID: convo.id)
                        }
                    },
                    onCancel: {
                        model.cancelPendingPayment()
                    }
                )
            }
            .platformTabBarHiddenWhenPushed(path.isEmpty && !showCircleDiscover)
            .onAppear { normalizePageMode() }
        }
    }

    // MARK: - Browse & shelves

    @ViewBuilder
    private var personBrowse: some View {
        if model.stageItems.isEmpty {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                BuddyPersonStage(items: model.stageItems, focusedID: $focusedBuddyID) { item in
                    BuddyZoomNavigationLink(item: item, namespace: zoomNamespace) {
                        BuddyDiscoverCard(
                            item: item,
                            enablesOpenTap: false,
                            onGreet: { greet(item) },
                            onInvite: { invite(item) }
                        )
                    }
                }

                if !gridItems.isEmpty {
                    DiscoverBrowseSection(
                        title: model.isPaidPage ? "更多陪玩" : "更多同好",
                        subtitle: model.isPaidPage ? "左右对比价位与档期" : "下滑继续发现附近的人"
                    ) {
                        BuddyPersonGrid(
                            items: gridItems,
                            zoomNamespace: zoomNamespace,
                            onChat: greet,
                            onInvite: invite
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var secondaryShelf: some View {
        if model.isPaidPage {
            DiscoverBrowseSection(
                title: "语音厅",
                subtitle: "进厅听麦，点麦位可打招呼或预约"
            ) {
                DiscoverHorizontalRail {
                    ForEach(model.allVoiceHalls) { hall in
                        BuddyVoiceHallShelfCard(hall: hall) {
                            path.append(hall)
                        }
                        .platformPosterRailFrame()
                    }
                }
            }
        } else if !model.allCircles.isEmpty {
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
