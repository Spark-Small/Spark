//
//  BuddiesView.swift
//  坐标系
//
//  找人玩：搭子双列墙；陪玩 = 精选横滑 + 推荐榜（穿插快捷长条）。
//

import SwiftUI

struct BuddiesView: View {
    @State private var navigation = TabNavigationState()
    @State private var showCircleDiscover = false
    @State private var showFilterSheet = false
    @State private var peopleSort: BuddyPeopleSort = .recommended
    @State private var bookingSort: BuddyBookingSort = .recommended
    @State private var boardPeriod: BuddyPaidBoardPeriod = .week
    @State private var weather = GreetingWeatherStore.shared
    @State private var location = LocationService.shared
    @State private var peerContactRoute: PeerContactRoute?
    @Namespace private var zoomNamespace

    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var model

    private var paidPeople: [DiscoverBuddyItem] {
        model.sortedBookings(model.stageItems, by: bookingSort)
    }

    private var searchPrompt: String {
        model.isPaidPage ? "搜昵称或擅长" : "搜搭子、羽毛球、夜骑…"
    }

    private var activeQuery: String {
        model.filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    if model.isPaidPage {
                        paidBrowse
                    } else {
                        socialBrowse
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, PlatformMetrics.sectionSpacing)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(PlatformSurface.groupedPage)
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: PlatformMetrics.sectionSpacing)
            }
            .platformTabRootScrollChrome(title: BuddiesCopy.rootTitle)
            .searchable(
                text: $model.filter.query,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: searchPrompt
            )
            .platformTabRootToolbar {
                BuddiesModeSwitchToolbar(
                    kind: $model.filter.kind,
                    hasActiveFilters: model.hasActiveBrowseFilters,
                    filterAccessibilityValue: model.browseRegionAccessibilityLabel,
                    onFilter: { showFilterSheet = true }
                )
            }
            .task(id: location.observationToken) {
                await weather.refresh()
                model.syncLocatedPlaceName(weather.reading?.placeName)
            }
            .onChange(of: weather.reading?.placeName) { _, place in
                model.syncLocatedPlaceName(place)
            }
            .buddyZoomNavigationDestination(namespace: zoomNamespace)
            .circleBrowseNavigationDestination()
            .peerContactDestination(route: $peerContactRoute)
            .navigationDestination(for: VoiceHall.self) { hall in
                BuddyVoiceHallRoomView(hall: hall)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .navigationDestination(isPresented: $showCircleDiscover) {
                ProfileCircleDiscoverView()
                    .toolbarVisibility(.hidden, for: .tabBar)
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
                    },
                    peopleSort: peopleSort,
                    bookingSort: bookingSort,
                    onPeopleSortChange: { peopleSort = $0 },
                    onBookingSortChange: { bookingSort = $0 }
                )
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .platformTransientFeedback($model.toastMessage)
            .sensoryFeedback(.success, trigger: model.toastMessage)
            .buddyBookingChrome(
                buddies: model,
                app: app,
                peerContactRoute: $peerContactRoute
            )
            .buddyOrgJoinChrome(
                buddies: model,
                openCircle: { navigation.openCircle($0) },
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .onAppear { normalizePageMode() }
            .onChange(of: model.filter.kind) { _, _ in
                peopleSort = .recommended
                bookingSort = .recommended
            }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - 免费找人

    private var socialPeople: [DiscoverBuddyItem] {
        model.sortedPeople(model.stageItems, by: peopleSort)
    }

    private func gridTitle(picksEmpty: Bool, query: String) -> String {
        if !query.isEmpty { return "搜索结果" }
        if picksEmpty {
            return switch peopleSort {
            case .recommended: "推荐"
            case .nearby: "附近的人"
            case .active: "刚活跃"
            }
        }
        return "更多附近"
    }

    private func gridSubtitle(picksEmpty: Bool, query: String) -> String {
        if !query.isEmpty { return "已按「\(query)」筛选" }
        if picksEmpty {
            return switch peopleSort {
            case .recommended: "看照片与状态，直接聊天"
            case .nearby: "按距离排序"
            case .active: "最近活跃的人"
            }
        }
        return "继续浏览"
    }

    @ViewBuilder
    private var socialBrowse: some View {
        let people = socialPeople
        let showPicks = peopleSort == .recommended && people.count > BuddyDiscoveryPicks.limit
        let (picks, rest) = showPicks
            ? BuddyDiscoveryPicks.split(people)
            : ([], people)

        if people.isEmpty {
            emptyState
        } else {
            if !picks.isEmpty {
                BuddyPickRail(
                    items: picks,
                    title: "为你精选",
                    subtitle: activeQuery.isEmpty
                        ? "找有趣的人，一起玩更快乐"
                        : "与「\(activeQuery)」更契合",
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet
                )
            }

            DiscoverBrowseSection(
                title: gridTitle(picksEmpty: picks.isEmpty, query: activeQuery),
                subtitle: gridSubtitle(picksEmpty: picks.isEmpty, query: activeQuery)
            ) {
                BuddyPersonGrid(
                    items: rest,
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet
                )
            }
        }

        if !model.allCircles.isEmpty {
            DiscoverBrowseSection(
                title: "兴趣圈子",
                subtitle: "找人之后，也可以进群继续聊",
                showsChevron: true,
                onSeeAll: { showCircleDiscover = true }
            ) {
                DiscoverHorizontalRail {
                    ForEach(model.allCircles) { circle in
                        BuddyPosterShelfCard.circle(circle) {
                            navigation.openCircle(circle)
                        }
                        .platformPosterRailFrame()
                    }
                }
            }
        }
    }

    // MARK: - 预约

    private var paidBoardItems: [DiscoverBuddyItem] {
        BuddyPaidMarketCatalog.ranked(paidPeople, period: boardPeriod)
    }

    private var paidFeaturedCompanions: [PaidCompanion] {
        let companions = paidPeople.compactMap { item -> PaidCompanion? in
            guard case .paid(let companion) = item else { return nil }
            return companion
        }
        let available = companions.filter(\.isAvailable)
        let rest = companions.filter { !$0.isAvailable }
        return Array((available + rest).prefix(5))
    }

    @ViewBuilder
    private var paidBrowse: some View {
        @Bindable var model = model

        if !paidFeaturedCompanions.isEmpty {
            DiscoverBrowseSection(
                title: "精选陪玩",
                subtitle: "先看近期可约、响应更快的人选"
            ) {
                BuddyFeaturedCompanionRail(
                    companions: paidFeaturedCompanions,
                    zoomNamespace: zoomNamespace,
                    onBook: { model.book($0) }
                )
            }
        }

        if paidPeople.isEmpty {
            emptyState
        } else {
            BuddyPaidLeaderboard(
                items: paidBoardItems,
                period: $boardPeriod,
                zoomNamespace: zoomNamespace,
                onBook: invite,
                onQuickEntry: handlePaidQuickEntry
            )
        }

        if !model.allVoiceHalls.isEmpty {
            BuddyVoiceChannelRail(halls: model.allVoiceHalls) { hall in
                navigation.path.append(hall)
            }
        }
    }

    private func handlePaidQuickEntry(_ entry: BuddyPaidQuickEntry) {
        switch entry {
        case .quickMatch:
            model.filter.serviceType = nil
            model.filter.availableOnly = true
            bookingSort = .earliest
        case .voiceParty:
            if let hall = model.allVoiceHalls.first(where: \.isLive) ?? model.allVoiceHalls.first {
                navigation.path.append(hall)
            } else {
                model.filter.serviceType = .voice
                model.filter.availableOnly = false
                bookingSort = .recommended
            }
        }
    }

    // MARK: - Browse

    private func normalizePageMode() {
        if model.filter.kind != .paid {
            model.filter.kind = .free
        }
    }

    private func greet(_ item: DiscoverBuddyItem) {
        peerContactRoute = app.openPeerContact(
            with: item.profile.nickname,
            context: .forBuddyItem(item)
        )
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
            || !model.filter.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)
        return ContentUnavailableView {
            Label(
                filtered
                    ? (isPaid ? "没有符合的陪玩" : "没有找到符合的人")
                    : (locating
                        ? "正在获取位置…"
                        : (isPaid ? "附近暂无可约的陪玩" : "附近暂时没有人")),
                systemImage: filtered ? "magnifyingglass" : (locating ? "location.fill" : "mappin.and.ellipse")
            )
        } description: {
            Text(
                filtered
                    ? "试试换个搜索词，或者放宽筛选条件"
                    : (locating
                        ? "定位完成后会按城市推荐，也可在筛选里手动指定城市"
                        : (isPaid
                            ? "可以扩大搜索范围，或切换到搭子页先找人聊天"
                            : "可以扩大搜索距离，或换个搜索词再试试"))
            )
        } actions: {
            if filtered {
                Button("清除筛选") {
                    model.resetBrowseFilters()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("调整筛选") {
                    showFilterSheet = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            } else if locating {
                Button("指定城市") {
                    showFilterSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else if isPaid {
                Button("找搭子") {
                    model.showSocialPage()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            } else {
                Button("放宽筛选") {
                    showFilterSheet = true
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
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
