//
//  ActivityLayoutDemoView.swift
//  坐标系
//
//  Apple TV / App Store 式布局演示：与活动 Tab 共用 ActivityBrowseShelfViews。
//

import SwiftUI

struct ActivityLayoutDemoView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var zoomNamespace

    private var shelves: [ActivityBrowseShelf] {
        ActivityLayoutDemoCatalog.shelves(
            activities: model.activities,
            joined: model.joinedActivities
        )
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if let spotlight = model.activities.first {
                        ActivityFeaturedSpotlightSection(
                            title: "今日焦点",
                            activity: spotlight,
                            zoomNamespace: zoomNamespace,
                            onJoin: join
                        )
                        .activityZoomSlot("demo-spotlight")
                        .padding(.bottom, PlatformMetrics.sectionSpacing)
                    }

                    LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                        ForEach(shelves) { shelf in
                            ActivityBrowseShelfSection(
                                shelf: shelf,
                                zoomNamespace: zoomNamespace,
                                showsSubtitle: false,
                                showsSeeAll: false,
                                onJoin: join
                            )
                            .activityZoomSlot("demo-\(shelf.id)")
                        }
                    }
                }
                .discoverBrowsePageColumn()
            }
            .discoverBrowseScrollChrome()
            .navigationTitle("布局演示")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .environment(\.activityZoomNamespace, nil)
            .activityZoomNavigationDestination(namespace: zoomNamespace)
        }
        .toolbarVisibility(.hidden, for: .tabBar)
        .tint(PlatformStatus.accent)
    }

    private func join(_ activity: Activity) {
        withAnimation(reduceMotion ? nil : .snappy) {
            _ = app.quickJoinActivity(activity) {}
        }
    }
}

// MARK: - Catalog

private enum ActivityLayoutDemoCatalog {
    static let minimumCount = 2

    static func shelves(activities: [Activity], joined: [Activity]) -> [ActivityBrowseShelf] {
        let open = activities.filter { !$0.isPast && $0.hasAvailableSpots }
        var shelves: [ActivityBrowseShelf] = []

        append(
            &shelves, id: "featured", title: "精选", layout: .editorial,
            items: Array(activities.dropFirst(1).prefix(5))
        )
        append(
            &shelves,
            id: "following",
            title: ActivityBrowseCopy.Shelf.followingTitle,
            layout: .following,
            items: following(from: joined, fallback: activities)
        )
        append(
            &shelves, id: "topcharts", title: "今日 Top 10", layout: .ranked,
            items: Array(activities.dropFirst(6).prefix(10))
        )
        append(
            &shelves, id: "hot", title: "热场活动", layout: .hot,
            items: Array(open.dropFirst(2).prefix(10))
        )
        append(
            &shelves,
            id: "free",
            title: ActivityBrowseCopy.Shelf.freeTitle,
            layout: .hot,
            items: Array(open.filter(\.isFree).prefix(10))
        )
        append(
            &shelves, id: "new", title: "新上架", layout: .editorial,
            items: Array(open.sorted { $0.date < $1.date }.dropFirst(2).prefix(5))
        )
        append(
            &shelves,
            id: "nearby",
            title: ActivityBrowseCopy.Shelf.nearbyTitle,
            layout: .hot,
            items: Array(open.filter(\.isNearby).prefix(10))
        )
        append(
            &shelves,
            id: "filling",
            title: ActivityBrowseCopy.Shelf.fillingTitle,
            layout: .hot,
            items: Array(open.filter { $0.isAlmostFull && !$0.isFull }.prefix(10))
        )
        append(
            &shelves,
            id: "tonight",
            title: ActivityBrowseCopy.Shelf.tonightTitle,
            layout: .following,
            items: tonight(from: open)
        )
        append(
            &shelves, id: "editors", title: "编辑之选", layout: .editorial,
            items: Array(activities.dropFirst(12).prefix(5))
        )
        append(
            &shelves, id: "list", title: "完整浏览", layout: .list,
            items: Array(activities.dropFirst(18).prefix(4))
        )

        return shelves
    }

    private static func append(
        _ shelves: inout [ActivityBrowseShelf],
        id: String,
        title: String,
        layout: ActivityBrowseShelfLayout,
        items: [Activity]
    ) {
        guard items.count >= minimumCount else { return }
        shelves.append(
            ActivityBrowseShelf(
                id: id,
                title: title,
                subtitle: nil,
                layout: layout,
                activities: items
            )
        )
    }

    private static func following(from joined: [Activity], fallback: [Activity]) -> [Activity] {
        let active = joined.filter { !$0.isPast }
        if active.count >= minimumCount { return Array(active.prefix(8)) }
        return Array(fallback.dropFirst(3).prefix(8))
    }

    private static func tonight(from open: [Activity]) -> [Activity] {
        let calendar = Calendar.current
        return Array(open.filter { activity in
            calendar.isDateInToday(activity.date)
                && calendar.component(.hour, from: activity.date) >= 17
        }.prefix(10))
    }
}

#Preview {
    ActivityLayoutDemoView()
        .environment(ActivitiesModel())
        .environment(AppModel())
}
