//
//  BuddiesView.swift
//  坐标系
//
//  找人玩：顶栏搜索开 Sheet（无 .searchable）；预约资产在「我的」。
//

import SwiftUI

struct BuddiesView: View {
    @State private var navigation = TabNavigationState()
    @State private var showCircleDiscover = false
    @State private var showFilterSheet = false
    @State private var showSearchSheet = false
    @State private var peopleSort: BuddyPeopleSort = .recommended
    @State private var bookingSort: BuddyBookingSort = .recommended
    @State private var boardPeriod: BuddyPaidBoardPeriod = .week
    @State private var seeAllRoute: BuddyBrowseSeeAllRoute?
    @State private var weather = GreetingWeatherStore.shared
    @State private var location = LocationService.shared
    @State private var peerContactRoute: PeerContactRoute?
    @Namespace private var zoomNamespace

    @Environment(AppModel.self) private var app
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

    private var isSearching: Bool { !activeQuery.isEmpty }

    private var rootTitle: String {
        model.filter.kind.stageTitle
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
                .discoverBrowsePageColumn()
            }
            .discoverBrowseScrollChrome()
            .platformTabRootScrollChrome(title: rootTitle)
            .platformTabRootTitleMenu {
                BuddiesModeTitleMenu(kind: $model.filter.kind)
            }
            .platformTabRootToolbar {
                BuddiesModeSwitchToolbar(
                    hasActiveFilters: model.hasActiveBrowseFilters,
                    hasActiveSearch: isSearching,
                    filterAccessibilityValue: model.browseRegionAccessibilityLabel,
                    onSearch: { showSearchSheet = true },
                    onFilter: { showFilterSheet = true }
                )
            }
            .tint(PlatformAction.cloverPurple)
            .task(id: location.observationToken) {
                await weather.refresh()
                model.syncLocatedPlaceName(weather.reading?.placeName)
            }
            .onChange(of: weather.reading?.placeName) { _, place in
                model.syncLocatedPlaceName(place)
            }
            .buddyZoomNavigationDestination(namespace: zoomNamespace)
            .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
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
            .navigationDestination(item: $seeAllRoute) { route in
                BuddyBrowseSeeAllView(
                    title: route.title,
                    items: seeAllItems(for: route),
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onBook: invite
                )
            }
            .sheet(isPresented: $showSearchSheet) {
                BuddyBrowseSearchSheet(
                    query: $model.filter.query,
                    prompt: searchPrompt
                )
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
            .platformFeedbackAlert($model.toastMessage)
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
            .onChange(of: model.filter.kind) { _, _ in
                peopleSort = .recommended
                bookingSort = .recommended
                model.filter.query = ""
            }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - 免费找人

    private var socialPeople: [DiscoverBuddyItem] {
        model.sortedPeople(model.stageItems, by: peopleSort)
    }

    private var freeWallTitle: String {
        peopleSort == .active
            ? BuddyBrowseCopy.Shelf.activeWallTitle
            : BuddyBrowseCopy.Shelf.listTitle
    }

    private var freeHome: BuddyBrowseHomeSnapshot {
        BuddyBrowseHomeCatalog.freeSnapshot(
            people: socialPeople,
            joinedCircleNames: model.joinedCircleNames,
            wallTitle: freeWallTitle
        )
    }

    @ViewBuilder
    private var socialBrowse: some View {
        let people = socialPeople

        if people.isEmpty {
            emptyState
        } else if isSearching {
            DiscoverBrowseSection(title: BuddyBrowseCopy.searchResultsTitle) {
                BuddyPersonGrid(
                    items: people,
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet
                )
            }
        } else {
            let home = freeHome
            browseHome(home, onBook: invite)
        }

        if !model.allCircles.isEmpty, !isSearching {
            BuddyInterestCirclesRail(
                circles: model.allCircles,
                onOpen: { navigation.openCircle($0) },
                onSeeAll: { showCircleDiscover = true }
            )
        }
    }

    // MARK: - 预约

    private var paidHome: BuddyBrowseHomeSnapshot {
        BuddyBrowseHomeCatalog.paidSnapshot(
            people: paidPeople,
            boardPeriod: boardPeriod,
            wallTitle: BuddyBrowseCopy.Shelf.paidWallTitle
        )
    }

    @ViewBuilder
    private var paidBrowse: some View {
        if paidPeople.isEmpty {
            emptyState
        } else if isSearching {
            DiscoverBrowseSection(title: BuddyBrowseCopy.searchResultsTitle) {
                BuddyPersonGrid(
                    items: paidPeople,
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onBook: invite
                )
            }
        } else {
            let home = paidHome
            browseHome(home, onBook: invite)
        }

        if !model.allVoiceHalls.isEmpty, !isSearching {
            BuddyVoiceChannelRail(halls: model.allVoiceHalls) { hall in
                navigation.path.append(hall)
            }
        }
    }

    @ViewBuilder
    private func browseHome(
        _ home: BuddyBrowseHomeSnapshot,
        onBook: @escaping (DiscoverBuddyItem) -> Void
    ) -> some View {
        if !home.spotlight.isEmpty {
            if model.isPaidPage {
                let companions = home.spotlight.compactMap { item -> PaidCompanion? in
                    guard case .paid(let companion) = item else { return nil }
                    return companion
                }
                if !companions.isEmpty {
                    BuddyFeaturedCompanionRail(
                        companions: companions,
                        zoomNamespace: zoomNamespace,
                        onBook: { model.book($0) }
                    )
                }
            } else {
                BuddyPickRail(
                    items: home.spotlight,
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onBook: onBook
                )
            }
        }

        if let board = home.leaderboard {
            BuddyBrowseShelfSection(
                shelf: board,
                intentQuery: activeQuery,
                zoomNamespace: zoomNamespace,
                boardPeriod: $boardPeriod,
                onChat: greet,
                onBook: onBook,
                onQuickEntry: handlePaidQuickEntry
            )
        }

        ForEach(home.rails) { shelf in
            BuddyBrowseShelfSection(
                shelf: shelf,
                intentQuery: activeQuery,
                zoomNamespace: zoomNamespace,
                onChat: greet,
                onBook: onBook,
                onSeeAll: openSeeAll
            )
        }

        if !home.wall.isEmpty {
            DiscoverBrowseSection(title: home.wallTitle) {
                BuddyPersonGrid(
                    items: home.wall,
                    intentQuery: activeQuery,
                    zoomNamespace: zoomNamespace,
                    onChat: greet,
                    onBook: onBook
                )
            }
        }
    }

    private func openSeeAll(_ shelf: BuddyBrowseShelf) {
        seeAllRoute = BuddyBrowseSeeAllRoute(
            id: shelf.id,
            title: shelf.title,
            itemIDs: shelf.items.map(\.id)
        )
    }

    private func seeAllItems(for route: BuddyBrowseSeeAllRoute) -> [DiscoverBuddyItem] {
        let pool = model.isPaidPage ? paidPeople : socialPeople
        let idSet = Set(route.itemIDs)
        let ordered = route.itemIDs.compactMap { id in pool.first { $0.id == id } }
        if ordered.count >= idSet.count { return ordered }
        // 查看全部：同维度放大到当前池中仍满足信号的人
        switch route.id {
        case "nearby":
            return pool.filter { $0.profile.isNearby }
        case "affinity":
            return pool.filter { !BuddyMatchScorer.sharedHobbies(with: $0.profile).isEmpty }
        case "tonight":
            return pool.filter(BuddyBrowseHomeCatalog.hasTonightSlot)
        case "following":
            return pool.filter { item in
                guard case .free(let buddy) = item else { return false }
                return model.joinedCircleNames.contains(buddy.circleName)
            }
        default:
            return ordered
        }
    }

    private func handlePaidQuickEntry(_ entry: BuddyPaidQuickEntry) {
        switch entry {
        case .quickMatch:
            // 快捷入口只打开筛选，不另开一套改条件的路径
            model.filter.availableOnly = true
            bookingSort = .earliest
            showFilterSheet = true
        case .voiceParty:
            if let hall = model.allVoiceHalls.first(where: \.isLive) ?? model.allVoiceHalls.first {
                navigation.path.append(hall)
            } else {
                model.filter.serviceType = .voice
                showFilterSheet = true
            }
        }
    }

    // MARK: - Actions

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
                            ? "可以扩大搜索范围，或切换到免费页先找人聊天"
                            : "可以扩大搜索距离，或换个搜索词再试试"))
            )
        } actions: {
            if filtered {
                Button("清除筛选") {
                    model.resetBrowseFilters()
                    peopleSort = .recommended
                    bookingSort = .recommended
                }
                .activityPrimaryCTA(controlSize: .large)
                Button("调整筛选") {
                    showFilterSheet = true
                }
                .activitySecondaryCTA(controlSize: .large)
            } else if locating {
                Button("指定城市") {
                    showFilterSheet = true
                }
                .activityPrimaryCTA(controlSize: .large)
            } else if isPaid {
                Button("找搭子") {
                    model.showSocialPage()
                }
                .activityPrimaryCTA(controlSize: .large)
            } else {
                Button("放宽筛选") {
                    showFilterSheet = true
                }
                .activityPrimaryCTA(controlSize: .large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }
}

#Preview {
    BuddiesView()
}
