//
//  ActivityBrowseShelfViews.swift
//  坐标系
//
//  活动发现货架：活动 Tab 官方卡片渲染。
//

import SwiftUI

// MARK: - Section

struct ActivityBrowseShelfSection: View {
    let shelf: ActivityBrowseShelf
    var zoomNamespace: Namespace.ID
    var onJoin: (Activity) -> Void

    var body: some View {
        DiscoverBrowseSection(title: shelf.title) {
            ActivityBrowseShelfRailContent(
                shelf: shelf,
                zoomNamespace: zoomNamespace,
                onJoin: onJoin
            )
        }
    }
}

// MARK: - Rails

struct ActivityBrowseShelfRailContent: View {
    @Environment(ActivitiesModel.self) private var model

    let shelf: ActivityBrowseShelf
    var zoomNamespace: Namespace.ID
    var onJoin: (Activity) -> Void

    var body: some View {
        switch shelf.layout {
        case .editorial:
            editorialRail(shelf.activities, shelfID: shelf.id)
        case .following:
            continueRail(shelf.activities)
        case .hot:
            eventRail(shelf.activities, shelfID: shelf.id)
        case .ranked:
            rankedRail(shelf.activities)
        case .list:
            listStack(shelf.activities)
        }
    }

    private func editorialRail(_ activities: [Activity], shelfID: String) -> some View {
        DiscoverHorizontalRail {
            ForEach(activities) { activity in
                PlatformEditorialCard(
                    activityID: activity.id,
                    zoomNamespace: zoomNamespace,
                    photo: activity.coverPhoto,
                    badge: ActivityBrowseShelfCopy.editorialBadge(for: activity, shelfID: shelfID),
                    title: activity.title,
                    metaLine: ActivityBrowseShelfCopy.editorialMeta(for: activity),
                    metaSymbol: activity.category.systemImage,
                    isJoined: model.isJoined(activity.id),
                    isFull: activity.isFull,
                    onJoin: { onJoin(activity) }
                )
                .platformEditorialRailFrame()
            }
        }
    }

    private func continueRail(_ activities: [Activity]) -> some View {
        DiscoverHorizontalRail {
            ForEach(activities) { activity in
                PlatformContinueCard(
                    activityID: activity.id,
                    zoomNamespace: zoomNamespace,
                    photo: activity.coverPhoto,
                    title: activity.title,
                    timeLine: Formatters.activityEventTime(from: activity.date),
                    metaLine: activity.districtLabel,
                    isJoined: model.isJoined(activity.id),
                    isFull: activity.isFull,
                    onJoin: joinAction(for: activity)
                )
                .platformContinueRailFrame()
            }
        }
    }

    private func eventRail(_ activities: [Activity], shelfID: String) -> some View {
        DiscoverHorizontalRail {
            ForEach(activities) { activity in
                PlatformEventCard(
                    activityID: activity.id,
                    zoomNamespace: zoomNamespace,
                    photo: activity.coverPhoto,
                    badge: ActivityBrowseShelfCopy.eventBadge(for: activity, shelfID: shelfID),
                    title: activity.title,
                    timeLine: Formatters.activityEventTime(from: activity.date),
                    metaLine: ActivityBrowseShelfCopy.eventMeta(for: activity, shelfID: shelfID),
                    isJoined: model.isJoined(activity.id),
                    isFull: activity.isFull,
                    onJoin: joinAction(for: activity)
                )
                .platformContinueRailFrame()
            }
        }
    }

    private func rankedRail(_ activities: [Activity]) -> some View {
        DiscoverHorizontalRail {
            ForEach(Array(activities.enumerated()), id: \.element.id) { index, activity in
                PlatformPosterRankCard(
                    activityID: activity.id,
                    zoomNamespace: zoomNamespace,
                    photo: activity.coverPhoto,
                    rank: index + 1,
                    title: activity.title,
                    genre: activity.category.title
                )
                .platformPosterRailFrame()
            }
        }
    }

    private func listStack(_ activities: [Activity]) -> some View {
        VStack(alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
            ForEach(activities) { activity in
                ActivityDiscoverCard(
                    activity: activity,
                    isJoined: model.isJoined(activity.id),
                    zoomNamespace: zoomNamespace,
                    onJoin: { onJoin(activity) }
                )
            }
        }
        .discoverBrowseContentInset()
    }

    private func joinAction(for activity: Activity) -> (() -> Void)? {
        model.isJoined(activity.id) ? nil : { onJoin(activity) }
    }
}

// MARK: - Spotlight Hero

struct ActivityFeaturedSpotlightSection: View {
    let activity: Activity
    var zoomNamespace: Namespace.ID
    var onJoin: (Activity) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        ActivityFeaturedCard(
            activity: activity,
            zoomNamespace: zoomNamespace,
            onJoin: { onJoin(activity) }
        )
        .modifier(ActivityFeaturedHeroAspectModifier(dynamicTypeSize: dynamicTypeSize))
        .discoverBrowseContentInset()
        .frame(maxWidth: .infinity)
    }
}

struct ActivityFeaturedHeroAspectModifier: ViewModifier {
    var dynamicTypeSize: DynamicTypeSize

    func body(content: Content) -> some View {
        if DiscoverAccessibility.prefersStackedCardChrome(for: dynamicTypeSize) {
            content
        } else {
            content.aspectRatio(PlatformMetrics.featuredCardAspectRatio, contentMode: .fit)
        }
    }
}

// MARK: - Copy

@MainActor
enum ActivityBrowseShelfCopy {
    static func editorialBadge(for activity: Activity, shelfID: String) -> String? {
        shelfID == "new"
            ? "新"
            : ActivityCardStatus.captionBadge(for: activity, fallback: "新")
    }

    static func editorialMeta(for activity: Activity) -> String {
        let tag = activity.tags.first ?? (activity.isFree ? ActivityCardStatus.free : activity.fee)
        let time = Formatters.activityEventTime(from: activity.date)
        return "\(activity.category.title) · \(tag) · \(time)"
    }

    static func eventBadge(for activity: Activity, shelfID: String) -> String? {
        switch shelfID {
        case "free": ActivityCardStatus.free
        case "nearby": activity.category.shortTitle
        case "filling": ActivityCardStatus.almostFull
        default: ActivityCardStatus.hotBadge(for: activity)
        }
    }

    static func eventMeta(for activity: Activity, shelfID: String) -> String {
        switch shelfID {
        case "nearby": activity.districtLabel
        case "filling": ActivityCardStatus.spotsText(for: activity)
        default: ActivityCardStatus.hotMetaLine(for: activity)
        }
    }
}
