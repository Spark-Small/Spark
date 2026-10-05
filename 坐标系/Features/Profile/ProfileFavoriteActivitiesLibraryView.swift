//
//  ProfileFavoriteActivitiesLibraryView.swift
//  坐标系
//
//  活动收藏列表（详情「更多」入口；根「我的」不挂）。
//

import SwiftUI
import CoordinateModels

struct ProfileFavoriteActivitiesLibraryView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Namespace private var zoomNamespace

    var body: some View {
        Group {
            if model.favoriteActivities.isEmpty {
                ProfileLibraryEmptyView(
                    title: "还没有收藏活动",
                    systemImage: "bookmark",
                    description: "在活动详情里点收藏，想去的局会出现在这里。"
                ) {
                    Button("去发现活动") {
                        app.focusActivitiesDiscoverBrowse()
                    }
                }
            } else {
                List {
                    ForEach(model.favoriteActivities) { activity in
                        ActivityZoomNavigationLink(
                            activity: activity,
                            namespace: zoomNamespace
                        ) {
                            favoriteRow(activity)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("取消收藏", systemImage: "bookmark.slash") {
                                PlatformMotion.withAnimation(.easeOut(duration: 0.25)) {
                                    model.toggleFavorite(activity.id)
                                }
                            }
                            .tint(.gray)
                        }
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                .platformAnimation(.easeOut(duration: 0.25), value: model.favoriteIDs)
                .profileSecondaryListChrome()
            }
        }
        .navigationTitle(ActivityBrowseCopy.favoritesLibrary)
        .navigationBarTitleDisplayMode(.inline)
        .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
    }

    private func favoriteRow(_ activity: Activity) -> some View {
        Label {
            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(activity.title)
                    .font(PlatformListTypography.primary)
                    .lineLimit(1)
                Text("\(Formatters.activityEventTime(from: activity.date)) · \(activity.location)")
                    .font(PlatformListTypography.secondary)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: PlatformConversationListRow.textToSecondarySpacing) {
                    Text(activity.fee)
                        .font(PlatformListTypography.footnote)
                        .foregroundStyle(activity.isFree ? PlatformStatus.success : .secondary)
                    if activity.isPast {
                        Text("已结束")
                            .font(PlatformListTypography.footnote)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        } icon: {
            Image(systemName: activity.category.systemImage)
                .foregroundStyle(.tint)
        }
    }
}
