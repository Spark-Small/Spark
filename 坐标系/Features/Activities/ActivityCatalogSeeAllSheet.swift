//
//  ActivityCatalogSeeAllSheet.swift
//  坐标系
//
//  分区「查看全部」：browser sheet + Zoom 打开详情（发现大卡列表）。
//

import SwiftUI

struct ActivityCatalogSeeAllSheet: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let shelf: ActivityBrowseShelf
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.discoverCardSpacing) {
                    Text(ActivityBrowseCopy.SeeAll.listCaption)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityAddTraits(.isHeader)

                    ForEach(Array(shelf.activities.enumerated()), id: \.element.id) { index, activity in
                        shelfRow(activity: activity, index: index)
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
                .padding(.vertical, PlatformMetrics.sectionHeaderSpacing)
            }
            .background(PlatformSurface.groupedPage)
            .navigationTitle(shelf.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .activityZoomSlot("see-all-\(shelf.id)")
        }
        .platformSheet(.browser)
    }

    @ViewBuilder
    private func shelfRow(activity: Activity, index: Int) -> some View {
        switch shelf.layout {
        case .ranked:
            HStack(alignment: .center, spacing: PlatformMetrics.cardFooterSpacing) {
                Text("\(index + 1)")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.secondary)
                    .frame(width: PlatformMetrics.seeAllRankColumnWidth, alignment: .trailing)
                    .accessibilityHidden(true)

                ActivityDiscoverCard(
                    activity: activity,
                    isJoined: model.isJoined(activity.id),
                    zoomNamespace: zoomNamespace,
                    enablesOpenTap: false,
                    onJoin: { join(activity) }
                )
            }
            .accessibilityElement(children: .contain)
        case .following, .hot, .list, .editorial:
            ActivityDiscoverCard(
                activity: activity,
                isJoined: model.isJoined(activity.id),
                zoomNamespace: zoomNamespace,
                enablesOpenTap: false,
                onJoin: shelf.layout == .following ? nil : { join(activity) }
            )
        }
    }

    private func join(_ activity: Activity) {
        withAnimation(reduceMotion ? nil : .snappy) {
            _ = app.quickJoinActivity(activity) {
                path.append(
                    ActivityZoomSource(
                        activityID: activity.id,
                        slot: "see-all-\(shelf.id)"
                    )
                )
            }
        }
    }
}
