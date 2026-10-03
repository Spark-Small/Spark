//
//  BuddiesView+Browse.swift
//  坐标系
//
//  搭子 Tab：按标题菜单当前模式展示单一货架；空态与深链消费。
//

import SwiftUI
import CoordinateModels

extension BuddiesView {
    // MARK: - Unified browse

    var socialPeople: [DiscoverBuddyItem] {
        model.sortedPeople(model.freeItems, by: peopleSort)
    }

    var freeWallTitle: String {
        peopleSort == .active
            ? BuddyBrowseCopy.Shelf.activeWallTitle
            : BuddyBrowseCopy.Shelf.listTitle
    }

    var freeHome: BuddyBrowseHomeSnapshot {
        BuddyBrowseHomeCatalog.freeSnapshot(
            people: socialPeople,
            joinedCircleNames: model.joinedCircleNames,
            wallTitle: freeWallTitle
        )
    }

    var paidHome: BuddyBrowseHomeSnapshot {
        BuddyBrowseHomeCatalog.paidSnapshot(
            people: paidPeople,
            boardPeriod: boardPeriod,
            wallTitle: BuddyBrowseCopy.Shelf.paidWallTitle
        )
    }

    var currentPeople: [DiscoverBuddyItem] {
        browseKind == .paid ? paidPeople : socialPeople
    }

    @ViewBuilder
    var unifiedBrowse: some View {
        switch browseKind {
        case .clubs:
            clubsBrowse
        case .free, .paid:
            if currentPeople.isEmpty {
                let showFullPageEmpty = socialPeople.isEmpty
                    && paidPeople.isEmpty
                    && !model.hasActiveBrowseFilters
                modeEmptyState
                if !showFullPageEmpty {
                    secondaryBrowse
                }
            } else {
                modeSectionBrowse
                secondaryBrowse
            }
        }
    }

    @ViewBuilder
    var clubsBrowse: some View {
        let circles = model.filteredCircles(sortedBy: clubSort)
        if model.allCircles.isEmpty {
            clubsEmptyState
        } else if circles.isEmpty {
            sectionEmptyState(
                message: BuddyBrowseCopy.Empty.clubsFilteredEmpty,
                showsFilterAction: model.hasActiveBrowseFilters
            )
        } else {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
                    count: PlatformMetrics.personGridColumnCount
                ),
                spacing: PlatformMetrics.discoverCardSpacing
            ) {
                ForEach(circles) { circle in
                    BuddyPosterShelfCard.circle(circle) {
                        navigation.openCircle(circle)
                    }
                }
            }
            .discoverBrowseContentInset()
        }
    }

    var clubsEmptyState: some View {
        ContentUnavailableView {
            Label(
                BuddyBrowseCopy.Empty.clubsEmptyTitle,
                systemImage: "person.3"
            )
        } description: {
            Text(BuddyBrowseCopy.Empty.clubsEmptyBody)
        } actions: {
            Button(BuddyBrowseCopy.Empty.clubsEmptyAction) {
                app.selectedTab = .profile
                model.presentation.beginComposeClub()
            }
            .activityPrimaryCTA(controlSize: .large)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlatformMetrics.emptyStateVerticalPadding)
    }

    func peerContactTitle(for item: DiscoverBuddyItem) -> String {
        app.peerContactActionTitle(
            for: item.profile.nickname,
            context: .forBuddyItem(item)
        )
    }

    @ViewBuilder
    var modeSectionBrowse: some View {
        switch browseKind {
        case .free:
            browseHome(freeHome, pool: .free, onBook: invite)
        case .paid:
            browseHome(paidHome, pool: .paid, onBook: invite)
        case .clubs:
            EmptyView()
        }
    }

    @ViewBuilder
    var modeEmptyState: some View {
        if socialPeople.isEmpty, paidPeople.isEmpty, !model.hasActiveBrowseFilters {
            combinedEmptyState
        } else {
            sectionEmptyState(
                message: sectionEmptyMessage(for: browseKind == .paid ? .paid : .free),
                showsFilterAction: model.hasActiveBrowseFilters
            )
        }
    }

    @ViewBuilder
    var secondaryBrowse: some View {
        if !model.allVoiceHalls.isEmpty {
            BuddyVoiceChannelRail(halls: model.allVoiceHalls) { hall in
                navigation.path.append(hall)
            }
        }
    }

    @ViewBuilder
    func browseHome(
        _ home: BuddyBrowseHomeSnapshot,
        pool: BuddyBrowsePool,
        onBook: @escaping (DiscoverBuddyItem) -> Void
    ) -> some View {
        if let hero = home.spotlight.first {
            BuddyFeaturedSpotlightSection(
                item: hero,
                intentQuery: "",
                contactActionTitle: peerContactTitle(for: hero),
                zoomNamespace: zoomNamespace,
                onAction: {
                    switch hero {
                    case .free: greet(hero)
                    case .paid: onBook(hero)
                    }
                },
                onContact: { greet(hero) },
                onBook: BuddyPersonBrowseChrome.isPaid(hero) ? { onBook(hero) } : nil
            )
        }

        if let board = home.leaderboard {
            BuddyBrowseShelfSection(
                shelf: board,
                intentQuery: "",
                zoomNamespace: zoomNamespace,
                boardPeriod: $boardPeriod,
                contactTitle: peerContactTitle,
                onChat: greet,
                onBook: onBook,
                onQuickEntry: handlePaidQuickEntry,
                onSeeAll: { openSeeAll($0, pool: pool) }
            )
        }

        ForEach(home.rails) { shelf in
            BuddyBrowseShelfSection(
                shelf: shelf,
                intentQuery: "",
                zoomNamespace: zoomNamespace,
                contactTitle: peerContactTitle,
                onChat: greet,
                onBook: onBook,
                onSeeAll: { openSeeAll($0, pool: pool) }
            )
        }

        if !home.wall.isEmpty {
            DiscoverBrowseSection(title: home.wallTitle) {
                BuddyPersonGrid(
                    items: home.wall,
                    intentQuery: "",
                    zoomNamespace: zoomNamespace,
                    contactTitle: peerContactTitle,
                    onChat: greet,
                    onBook: onBook
                )
            }
        }
    }

    func openSeeAll(_ shelf: BuddyBrowseShelf, pool: BuddyBrowsePool) {
        seeAllRoute = BuddyBrowseSeeAllRoute(
            id: shelf.id,
            title: shelf.title,
            itemIDs: shelf.items.map(\.id),
            pool: pool
        )
    }

    func seeAllItems(for route: BuddyBrowseSeeAllRoute) -> [DiscoverBuddyItem] {
        if route.id == "leaderboard" {
            return BuddyPaidMarketCatalog.ranked(paidPeople, period: boardPeriod)
        }
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

    func handlePaidQuickEntry(_ entry: BuddyPaidQuickEntry) {
        switch entry {
        case .quickMatch:
            // 即时生效：与活动筛选同族，不绕道「应用」Sheet
            model.filter.availableOnly = true
            bookingSort = .earliest
        case .voiceParty:
            if let hall = model.allVoiceHalls.first(where: \.isLive) ?? model.allVoiceHalls.first {
                navigation.path.append(hall)
            } else {
                model.filter.serviceType = .voice
                showFilterSheet = true
            }
        }
    }
}

#Preview {
    let app = AppModel.preview
    let location = LocationService()
    return BuddiesView()
        .environment(app)
        .environment(app.buddies)
        .environment(app.messages)
        .environment(app.activities)
        .environment(GreetingWeatherStore(locationService: location))
        .environment(location)
}
