//
//  CommunityRelatedActivityLink.swift
//  坐标系
//
//  帖子关联活动的 Zoom / 推入入口（仅详情；Feed 不展示）。
//

import SwiftUI
import CoordinateModels

struct CommunityRelatedActivityLink: View {
    let activity: Activity

    @Environment(\.activityZoomNamespace) private var zoomNamespace

    var body: some View {
        Group {
            if let zoomNamespace {
                ActivityZoomNavigationLink(activity: activity, namespace: zoomNamespace) {
                    linkLabel
                }
            } else {
                NavigationLink {
                    ActivityDetailView(activity: activity)
                        .toolbarVisibility(.hidden, for: .tabBar)
                } label: {
                    linkLabel
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var linkLabel: some View {
        HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
            PlatformListSymbolAvatar(
                systemName: activity.category.systemImage,
                side: PlatformConversationListRow.imageSide
            )

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(CommunityBrowseCopy.relatedActivityLabel(activity.title))
                Text(Formatters.activityEventTime(from: activity.date))
                    .font(PlatformListTypography.trailing)
            }
            .font(PlatformListTypography.secondary)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
