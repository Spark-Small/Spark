//
//  BuddiesView.swift
//  坐标系
//
//  找人玩：同页展示找搭子 + 约陪玩（零切换）；顶栏搜索开 Sheet。
//

import SwiftUI
import CoordinateModels

struct BuddiesView: View {
    @State private var navigation = TabNavigationState()
    @State private var showCircleDiscover = false
    @State private var voiceHallExpanded = false
    @State private var showFilterSheet = false
    @State private var showSearchSheet = false
    @State private var peopleSort: BuddyPeopleSort = .recommended
    @State private var bookingSort: BuddyBookingSort = .recommended
    @State private var boardPeriod: BuddyPaidBoardPeriod = .week
    @State private var seeAllRoute: BuddyBrowseSeeAllRoute?
    @Environment(GreetingWeatherStore.self) private var weather
    @Environment(LocationService.self) private var location
    @State private var peerContactRoute: PeerContactRoute?
    @Namespace private var zoomNamespace

    @Environment(AppModel.self) private var app
    @Environment(BuddiesModel.self) private var model
    @Environment(MessagesModel.self) private var messages

    private var paidPeople: [DiscoverBuddyItem] {
        model.sortedBookings(model.paidItems, by: bookingSort)
    }

    private var activeQuery: String {
        model.filter.query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !activeQuery.isEmpty }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    if model.actionableBookingCount > 0, !isSearching {
                        BuddyMyBookingsEntryBanner(
                            bookingCount: model.actionableBookingCount,
                            attentionCount: model.pendingBookingAttentionCount,
                            onOpen: { app.openMyBookings() }
                        )
                    }

                    unifiedBrowse
                }
                .discoverBrowsePageColumn()
            }
            .discoverBrowseScrollChrome()
            .platformTabRootScrollChrome(title: BuddyBrowseCopy.rootTitle)
            .platformTabRootToolbar {
                buddiesTabToolbar
            }
            .tint(PlatformAction.cloverPurple)
            .task(id: location.observationToken) {
                await weather.refresh()
                model.syncLocatedPlaceName(weather.reading?.placeName)
            }
            .onChange(of: weather.reading?.placeName) { _, place in
                model.syncLocatedPlaceName(place)
            }
            .circleBrowseNavigationDestination()
            .circlePeerChatNavigationDestination()
            .buddyZoomNavigationDestination(namespace: zoomNamespace)
            .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
            .peerContactDestination(route: $peerContactRoute)
            .navigationDestination(for: VoiceHall.self) { hall in
                BuddyVoiceHallRoomView(hall: hall)
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .navigationDestination(isPresented: $showCircleDiscover) {
                ProfileCircleDiscoverView()
                    .toolbarVisibility(.hidden, for: .tabBar)
            }
            .onAppear {
                consumePendingBuddiesNavigation()
                consumePendingSocialLanding()
            }
            .onChange(of: app.pendingBuddiesRoute) { _, route in
                guard route != nil else { return }
                consumePendingBuddiesNavigation()
            }
            .onChange(of: model.pendingShowCircleDiscover) { _, pending in
                guard pending else { return }
                consumePendingSocialLanding()
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
                    prompt: BuddyBrowseCopy.unifiedSearchPrompt
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
            .sheet(isPresented: $model.isComposingClub) {
                CircleComposeSheet { circle in
                    if let convo = messages.startCircleChat(
                        for: circle,
                        memberName: app.user.name
                    ) {
                        model.attachJoinConversation(convo.id)
                    }
                }
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .platformFeedbackAlert($model.toastMessage)
            .buddyBookingChrome(buddies: model)
            .buddyOrgJoinChrome(
                buddies: model,
                openCircle: { navigation.openCircle($0) },
                openConversation: { conversationID in
                    openClubConversation(conversationID)
                }
            )
        }
        .tabNavigationState(navigation)
    }

    private func openClubConversation(_ conversationID: UUID) {
        guard let conversation = messages.conversations.first(where: { $0.id == conversationID }),
              conversation.kind == .circle,
              let circleID = conversation.relatedCircleID,
              let circle = model.circle(id: circleID)
        else {
            app.openMessages(conversationID: conversationID)
            return
        }
        guard let route = app.prepareClubGroupChatRoute(for: circle) else { return }
        navigation.openClubGroupChat(for: circle, route: route)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var buddiesTabToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button("创建俱乐部", systemImage: "plus") {
                model.isComposingClub = true
            }
            .accessibilityHint("自定义名称，创建本地俱乐部")

            Button("搜索", systemImage: "magnifyingglass") {
                showSearchSheet = true
            }
            .symbolVariant(isSearching ? .fill : .none)
            .accessibilityHint("搜索昵称、兴趣或擅长")
            .accessibilityValue(isSearching ? "已输入关键词" : "未搜索")

            Button(
                model.hasActiveBrowseFilters ? "筛选（已启用）" : "筛选",
                systemImage: "line.3.horizontal.decrease"
            ) {
                showFilterSheet = true
            }
            .symbolVariant(model.hasActiveBrowseFilters ? .fill : .none)
            .accessibilityHint("打开筛选：地区、性别、距离、兴趣、排序")
            .accessibilityValue(model.browseRegionAccessibilityLabel)
        }
    }

    // MARK: - Unified browse

    private var socialPeople: [DiscoverBuddyItem] {
        model.sortedPeople(model.freeItems, by: peopleSort)
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

    private var paidHome: BuddyBrowseHomeSnapshot {
        BuddyBrowseHomeCatalog.paidSnapshot(
            people: paidPeople,
            boardPeriod: boardPeriod,
            wallTitle: BuddyBrowseCopy.Shelf.paidWallTitle
        )
    }

    @ViewBuilder
    private var unifiedBrowse: some View {
        if isSearching {
            searchResultsBrowse
        } else {
            socialSectionBrowse
            paidSectionBrowse
            secondaryBrowse
        }
    }

    @ViewBuilder
    private var searchResultsBrowse: some View {
        if socialPeople.isEmpty, paidPeople.isEmpty {
            combinedEmptyState
        } else {
            if !socialPeople.isEmpty {
                DiscoverBrowseSection(title: BuddyKind.free.stageTitle) {
                    BuddyPersonGrid(
                        items: socialPeople,
                        intentQuery: activeQuery,
                        zoomNamespace: zoomNamespace,
                        onChat: greet
                    )
                }
            }
            if !paidPeople.isEmpty {
                DiscoverBrowseSection(title: BuddyKind.paid.stageTitle) {
                    BuddyPersonGrid(
                        items: paidPeople,
                        intentQuery: activeQuery,
                        zoomNamespace: zoomNamespace,
                        onChat: greet,
                        onBook: invite
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var socialSectionBrowse: some View {
        DiscoverBrowseSection(title: BuddyKind.free.stageTitle) {
            if socialPeople.isEmpty {
                sectionEmptyState(
                    message: sectionEmptyMessage(for: .free),
                    showsFilterAction: model.hasActiveBrowseFilters || isSearching
                )
            } else {
                browseHome(freeHome, pool: .free, onBook: invite)
            }
        }
    }

    @ViewBuilder
    private var paidSectionBrowse: some View {
        DiscoverBrowseSection(title: BuddyKind.paid.stageTitle) {
            if paidPeople.isEmpty {
                sectionEmptyState(
                    message: sectionEmptyMessage(for: .paid),
                    showsFilterAction: model.hasActiveBrowseFilters || isSearching
                )
            } else {
                browseHome(paidHome, pool: .paid, onBook: invite)
            }
        }
    }

    @ViewBuilder
    private var secondaryBrowse: some View {
        if !model.allCircles.isEmpty {
            BuddyInterestCirclesRail(
                circles: model.allCircles,
                onOpen: { navigation.openCircle($0) },
                onSeeAll: { showCircleDiscover = true }
            )
        }

        if !model.allVoiceHalls.isEmpty {
            DisclosureGroup(isExpanded: $voiceHallExpanded) {
                BuddyVoiceChannelRail(halls: model.allVoiceHalls) { hall in
                    navigation.path.append(hall)
                }
            } label: {
                Label(BuddyBrowseCopy.VoiceHall.sectionTitle, systemImage: "speaker.wave.2.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.horizontal, PlatformMetrics.contentInset)
            .padding(.top, model.allCircles.isEmpty ? 0 : PlatformMetrics.sectionSpacing)
        }
    }

    @ViewBuilder
    private func browseHome(
        _ home: BuddyBrowseHomeSnapshot,
        pool: BuddyBrowsePool,
        onBook: @escaping (DiscoverBuddyItem) -> Void
    ) -> some View {
        if !home.spotlight.isEmpty {
            switch pool {
            case .paid:
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
            case .free:
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
                onSeeAll: { openSeeAll($0, pool: pool) }
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

    private func openSeeAll(_ shelf: BuddyBrowseShelf, pool: BuddyBrowsePool) {
        seeAllRoute = BuddyBrowseSeeAllRoute(
            id: shelf.id,
            title: shelf.title,
            itemIDs: shelf.items.map(\.id),
            pool: pool
        )
    }

    private func seeAllItems(for route: BuddyBrowseSeeAllRoute) -> [DiscoverBuddyItem] {
        let pool = route.pool == .paid ? paidPeople : socialPeople
        let idSet = Set(route.itemIDs)
        let ordered = route.itemIDs.compactMap { id in pool.first { $0.id == id } }
        if ordered.count >= idSet.count { return ordered }
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

    // MARK: - Empty states

    private func sectionEmptyMessage(for pool: BuddyBrowsePool) -> String {
        let filtered = model.hasActiveBrowseFilters || isSearching
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)

        if filtered {
            return pool == .paid ? "没有符合的陪玩" : "没有找到符合的同好"
        }
        if locating {
            return "正在获取位置…"
        }
        return pool == .paid ? "附近暂无可约的陪玩" : "附近暂时没有人"
    }

    @ViewBuilder
    private func sectionEmptyState(message: String, showsFilterAction: Bool) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if showsFilterAction {
                Button("调整筛选") {
                    showFilterSheet = true
                }
                .font(.footnote.weight(.semibold))
                .buttonStyle(.plain)
                .foregroundStyle(PlatformAction.brandAccent)
            }
        }
        .discoverBrowseContentInset()
        .padding(.vertical, PlatformMetrics.formRowVerticalPadding)
    }

    private var combinedEmptyState: some View {
        let filtered = model.hasActiveBrowseFilters || isSearching
        let locating = model.usesSystemLocation
            && (model.locatedPlaceName == nil || model.locatedPlaceName?.isEmpty == true)
        let supplyPending = !BuddiesSupplyPolicy.allowsSampleDiscoverCatalog && !filtered && !locating

        return ContentUnavailableView {
            Label(
                filtered
                    ? "没有匹配结果"
                    : (locating
                        ? "正在获取位置…"
                        : (supplyPending
                            ? BuddiesSupplyPolicy.discoverEmptyTitle
                            : "附近暂时没有人")),
                systemImage: filtered
                    ? "magnifyingglass"
                    : (locating
                        ? "location.fill"
                        : (supplyPending ? "person.2.slash" : "mappin.and.ellipse"))
            )
        } description: {
            Text(
                filtered
                    ? "试试换个搜索词，或者放宽筛选条件"
                    : (locating
                        ? "定位完成后会按城市推荐，也可在筛选里手动指定城市"
                        : (supplyPending
                            ? BuddiesSupplyPolicy.discoverEmptyDescription
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
            } else if !supplyPending {
                Button("放宽筛选") {
                    showFilterSheet = true
                }
                .activityPrimaryCTA(controlSize: .large)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
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

    private func consumePendingSocialLanding() {
        guard model.pendingShowCircleDiscover else { return }
        model.pendingShowCircleDiscover = false
        showCircleDiscover = true
    }

    private func consumePendingBuddiesNavigation() {
        guard let route = app.pendingBuddiesRoute else { return }
        app.pendingBuddiesRoute = nil
        switch route {
        case .clubDiscover:
            showCircleDiscover = true
        }
    }
}

#Preview {
    BuddiesView()
}
