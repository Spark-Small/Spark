//
//  ActivityFavoritesView.swift
//  坐标系
//
//  活动页「更多」入口：仅收藏的活动。社区分享收藏在社区左上角 Menu。
//

import SwiftUI

struct ActivityFavoritesView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if model.favoriteActivities.isEmpty {
                    ContentUnavailableView(
                        "还没有收藏活动",
                        systemImage: "bookmark",
                        description: Text("在活动详情里点收藏，想去的局会出现在这里。")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(model.favoriteActivities) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            favoriteRow(activity)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("取消收藏", systemImage: "bookmark.slash") {
                                model.toggleFavorite(activity.id)
                            }
                            .tint(.gray)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .listSectionSpacing(.compact)
            .navigationTitle("收藏的活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .platformSheet(.browser)
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
