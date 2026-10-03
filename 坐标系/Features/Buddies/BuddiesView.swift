//
//  BuddiesView.swift
//  坐标系
//
//  找人玩：标题菜单切换找搭子 / 约陪玩 / 俱乐部；顶栏与五 Tab 同套 platformTabRoot*；
//  三模式 Trailing 筛选 Menu（条件分流）。
//

import SwiftData
import SwiftUI
import CoordinateModels
import CoordinateFeatureFlags

struct BuddiesView: View {
    @State var navigation = TabNavigationState()
    @State var showFilterSheet = false
    @State var peopleSort: BuddyPeopleSort = .recommended
    @State var bookingSort: BuddyBookingSort = .recommended
    @State var clubSort: BuddyClubSort = .active
    @State var isBrowsingRecents = false
    @State var boardPeriod: BuddyPaidBoardPeriod = .week
    @State var seeAllRoute: BuddyBrowseSeeAllRoute?
    @State var discoverBrowseScrollRequest = 0
    @Environment(GreetingWeatherStore.self) var weather
    @Environment(LocationService.self) var location
    @State var peerContactRoute: PeerContactRoute?
    @Namespace var zoomNamespace

    @Environment(AppModel.self) var app
    @Environment(BuddiesModel.self) var model
    @Environment(MessagesModel.self) var messages
    @Query(sort: \RecentBrowseItem.viewedAt, order: .reverse)
    var browseItems: [RecentBrowseItem]

    var browseKind: BuddyKind { model.filter.kind }

    var paidPeople: [DiscoverBuddyItem] {
        model.sortedBookings(model.paidItems, by: bookingSort)
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var model = model

        NavigationStack(path: $navigation.path) {
            ScrollViewReader { proxy in
                ScrollView {
                    // 与活动发现同构：锚点在 spacing:0 外层，避免大标题下多吃一段 sectionSpacing。
                    VStack(alignment: .leading, spacing: 0) {
                        Color.clear
                            .frame(height: 0)
                            .id(BuddyBrowseCopy.ScrollAnchor.discoverBrowse)

                        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                            if isBrowsingRecents {
                                recentsBrowseContent
                            } else {
                                unifiedBrowse
                            }
                        }
                    }
                    .discoverBrowsePageColumn()
                }
                .discoverBrowseScrollChrome()
                .scrollBounceBehavior(.basedOnSize)
                .scrollEdgeEffectStyle(.soft, for: .bottom)
                .platformTabRootScrollChrome(title: browseNavigationTitle)
                .platformTabRootTitleMenu {
                    BuddiesModeTitleMenu(
                        kind: $model.filter.kind,
                        isBrowsingRecents: isBrowsingRecents,
                        hasRecents: hasBuddiesRecents,
                        onSelectKind: { selectBrowseKind($0) },
                        onSelectRecents: { selectBrowseRecents() }
                    )
                }
                .platformTabRootToolbar {
                    if !isBrowsingRecents, browseKind.usesBrowseFilters {
                        BuddiesModeSwitchToolbar(
                            filter: $model.filter,
                            peopleSort: $peopleSort,
                            bookingSort: $bookingSort,
                            clubSort: $clubSort,
                            hasActiveFilters: model.hasActiveBrowseFilters,
                            toolbarSystemImage: model.browseFilterToolbarSystemImage,
                            filterAccessibilityValue: model.browseFilterAccessibilitySummary,
                            onOpenDeepFilters: { showFilterSheet = true }
                        )
                    }
                }
                .refreshable {
                    if FeatureFlags.useRemoteBuddies {
                        await app.resyncRemoteReadPath()
                    } else {
                        await model.reloadFromRepository()
                    }
                }
                .onChange(of: model.filter.kind) { _, _ in
                    isBrowsingRecents = false
                    discoverBrowseScrollRequest += 1
                }
                .onChange(of: isBrowsingRecents) { _, _ in
                    discoverBrowseScrollRequest += 1
                }
                .onChange(of: hasBuddiesRecents) { _, hasRecents in
                    if !hasRecents, isBrowsingRecents {
                        selectBrowseKind(.free)
                    }
                }
                .onChange(of: discoverBrowseScrollRequest) { _, _ in
                    PlatformMotion.withAnimation(.snappy) {
                        proxy.scrollTo(
                            BuddyBrowseCopy.ScrollAnchor.discoverBrowse,
                            anchor: .top
                        )
                    }
                }
                .onAppear {
                    if !model.filter.query.isEmpty {
                        model.filter.query = ""
                    }
                }
            }
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
            .onAppear {
                consumePendingBuddiesNavigation()
                consumePendingSocialLanding()
                consumePendingInviteActivityOpen()
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
                    intentQuery: "",
                    zoomNamespace: zoomNamespace,
                    contactTitle: peerContactTitle,
                    onChat: greet,
                    onBook: invite
                )
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
                .toolbarVisibility(.hidden, for: .tabBar)
            }
            .platformFeedbackAlert($model.presentation.toastMessage)
            .buddyBookingChrome(buddies: model, app: app)
            .buddyOrgJoinChrome(
                buddies: model,
                messages: messages,
                memberName: app.user.name,
                blockedUserNames: app.blockedUserNames,
                onBrowseBuddies: { app.selectedTab = .buddies },
                openCircle: { navigation.openCircle($0) },
                openConversation: { conversationID in
                    openClubConversation(conversationID)
                }
            )
        }
        .tabNavigationState(navigation)
    }

    func openClubConversation(_ conversationID: UUID) {
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
}
