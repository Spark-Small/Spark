//
//  ProfileHomeLibraryEmbeds.swift
//  坐标系
//
//  「我的」主页活动 / 陪玩 / 俱乐部档：页内嵌卡，不进库页。空态见 ProfileHomeTabEmptyRegion。
//

import CoordinateModels
import SwiftUI

// MARK: - 活动

struct ProfileHomeActivitiesEmbed: View {
    var zoomNamespace: Namespace.ID

    @Environment(ActivitiesModel.self) private var activities

    private var visible: [Activity] {
        ProfileHomeTabContent.activities(from: activities)
    }

    var body: some View {
        LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            ForEach(visible) { activity in
                let hosting = activities.isHost(activity)
                ProfileMyActivitiesCard(
                    activity: activity,
                    zoomNamespace: zoomNamespace,
                    intent: hosting ? .browseDetail : .participantPass,
                    badge: ProfileMyActivitiesStatusPresentation.badge(
                        for: activity,
                        isHost: hosting,
                        isWaitlisted: activities.isWaitlisted(activity.id)
                    )
                )
            }
        }
        .discoverBrowseContentInset()
        .padding(.vertical, PlatformMetrics.minContentGap)
    }
}

// MARK: - 陪玩

struct ProfileHomeCompanionsEmbed: View {
    @Environment(BuddiesModel.self) private var buddies

    private var visible: [BuddyBookingRecord] {
        ProfileHomeTabContent.companions(from: buddies)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: PlatformMetrics.minContentGap) {
            ForEach(visible) { record in
                ProfileMyCompanionsCard(
                    record: record,
                    photo: buddies.item(
                        for: record.companionNickname,
                        userID: record.companionUserID
                    )?.profile.coverPhoto,
                    badge: ProfileMyCompanionsStatusPresentation.badge(for: record)
                )
            }
        }
        .discoverBrowseContentInset()
        .padding(.vertical, PlatformMetrics.minContentGap)
    }
}

// MARK: - 俱乐部

struct ProfileHomeClubsEmbed: View {
    @Environment(BuddiesModel.self) private var buddies
    @Environment(MessagesModel.self) private var messages
    @Environment(AppModel.self) private var app
    @Environment(TabNavigationState.self) private var navigation

    private var visible: [InterestCircle] {
        ProfileHomeTabContent.clubs(from: buddies)
    }

    private var columns: [GridItem] {
        Array(
            repeating: GridItem(.flexible(), spacing: PlatformMetrics.minContentGap),
            count: PlatformMetrics.personGridColumnCount
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: PlatformMetrics.minContentGap) {
            ForEach(visible) { circle in
                BuddyPosterShelfCard.circle(
                    circle,
                    memberCount: buddies.displayedMemberCount(
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
        .padding(.vertical, PlatformMetrics.minContentGap)
    }
}
