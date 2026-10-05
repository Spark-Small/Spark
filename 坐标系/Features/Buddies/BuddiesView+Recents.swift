//
//  BuddiesView+Recents.swift
//  坐标系
//
//  搭子「最近浏览」：人用双列人像卡、俱乐部用海报网格，对齐发现货架（非纯文字行）。
//

import SwiftUI
import CoordinateModels

extension BuddiesView {
    private static let buddiesRecentKinds: Set<RecentBrowseKind> = [.buddy, .companion, .club]

    var buddiesRecentRecords: [RecentBrowseRecord] {
        browseItems
            .filter { Self.buddiesRecentKinds.contains($0.kind) }
            .prefix(ProfileRecentBrowseStore.maxItemsPerKind)
            .map(\.asRecord)
    }

    var hasBuddiesRecents: Bool { !buddiesRecentRecords.isEmpty }

    func selectBrowseKind(_ kind: BuddyKind) {
        isBrowsingRecents = false
        model.filter.kind = kind
    }

    func selectBrowseRecents() {
        isBrowsingRecents = true
    }

    /// 退出「最近浏览」，回到进入前的找搭子 / 约陪玩 / 俱乐部（`filter.kind` 未改）。
    func exitBrowseRecents() {
        isBrowsingRecents = false
    }

    var browseNavigationTitle: String {
        isBrowsingRecents ? BuddyBrowseCopy.recentsTitle : browseKind.stageTitle
    }

    @ToolbarContentBuilder
    var recentsExitToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(BuddyBrowseCopy.recentsBack, action: exitBrowseRecents)
                .platformNavigationBarItemChrome()
                .accessibilityHint(BuddyBrowseCopy.recentsBackHint(browseKind.stageTitle))
        }
    }

    var recentPeopleItems: [DiscoverBuddyItem] {
        var seen = Set<DiscoverBuddyItem.ID>()
        var ordered: [DiscoverBuddyItem] = []
        for record in buddiesRecentRecords where record.kind == .buddy || record.kind == .companion {
            guard let item = model.discoverItem(id: record.targetID),
                  seen.insert(item.id).inserted
            else { continue }
            ordered.append(item)
        }
        return ordered
    }

    var recentCircles: [InterestCircle] {
        var seen = Set<InterestCircle.ID>()
        var ordered: [InterestCircle] = []
        for record in buddiesRecentRecords where record.kind == .club {
            guard let circle = model.circle(id: record.targetID),
                  seen.insert(circle.id).inserted
            else { continue }
            ordered.append(circle)
        }
        return ordered
    }

    @ViewBuilder
    var recentsBrowseContent: some View {
        let people = recentPeopleItems
        let clubs = recentCircles

        if people.isEmpty, clubs.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                if !people.isEmpty {
                    DiscoverBrowseSection(title: BuddyBrowseCopy.recentsSectionPeople) {
                        BuddyPersonGrid(
                            items: people,
                            intentQuery: "",
                            zoomNamespace: zoomNamespace,
                            contactTitle: peerContactTitle,
                            onChat: greet,
                            onBook: invite
                        )
                    }
                }

                if !clubs.isEmpty {
                    DiscoverBrowseSection(title: BuddyBrowseCopy.recentsSectionClubs) {
                        LazyVGrid(
                            columns: Array(
                                repeating: GridItem(.flexible(), spacing: PlatformMetrics.discoverCardSpacing),
                                count: PlatformMetrics.personGridColumnCount
                            ),
                            spacing: PlatformMetrics.discoverCardSpacing
                        ) {
                            ForEach(clubs) { circle in
                                BuddyPosterShelfCard.circle(
                                    circle,
                                    memberCount: model.displayedMemberCount(
                                        for: circle,
                                        messages: messages,
                                        viewerName: app.user.name
                                    )
                                ) {
                                    navigation.openCircle(circle)
                                }
                            }
                        }
                        .discoverBrowseContentInset()
                    }
                }
            }
        }
    }
}
