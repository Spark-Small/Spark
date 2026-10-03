//
//  ProfileLibraryHubViews.swift
//  坐标系
//
//  「我的」二级库入口：活动与行程 / 广场内容（根页只留一行）。
//  目的地由 Profile 根栈已注册的 ProfileRoute / CommunityLibraryDestination 承接。
//

import SwiftUI
import CoordinateModels

/// 活动发起 / 报名 / 邀约合并入口。
struct ProfileActivitiesLibraryHubView: View {
    @Environment(BuddiesModel.self) private var buddies

    private var pendingInviteCount: Int {
        buddies.inviteRecords.filter { $0.status == .pending }.count
    }

    var body: some View {
        List {
            Section {
                NavigationLink(value: ProfileRoute.hostedActivities) {
                    Label(ProfileDashboardCopy.activityHosted, systemImage: "calendar.badge.plus")
                        .platformContentSymbolStyle()
                }
                NavigationLink(value: ProfileRoute.joinedActivities) {
                    Label(ProfileDashboardCopy.activityJoined, systemImage: "calendar")
                        .platformContentSymbolStyle()
                }
                NavigationLink(value: ProfileRoute.activityInvites) {
                    LabeledContent {
                        if pendingInviteCount > 0 {
                            Text("\(pendingInviteCount)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    } label: {
                        Label(ProfileDashboardCopy.activityInvites, systemImage: "paperplane.fill")
                            .platformContentSymbolStyle()
                    }
                }
            } footer: {
                Text(ProfileDashboardCopy.activitiesLibraryFooter)
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.activitiesLibraryTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// 广场内容库五项合并入口。
struct ProfileCommunityLibraryHubView: View {
    var body: some View {
        List {
            Section {
                NavigationLink(value: CommunityLibraryDestination.bookmarks) {
                    Label(ProfileDashboardCopy.communityBookmarks, systemImage: "bookmark.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink(value: CommunityLibraryDestination.liked) {
                    Label(ProfileDashboardCopy.communityLiked, systemImage: "heart.fill")
                        .platformContentSymbolStyle()
                }
                NavigationLink(value: CommunityLibraryDestination.myPosts) {
                    Label(ProfileDashboardCopy.communityMyPosts, systemImage: "square.and.pencil")
                        .platformContentSymbolStyle()
                }
                NavigationLink(value: CommunityLibraryDestination.reposts) {
                    Label(ProfileDashboardCopy.communityReposts, systemImage: "arrow.2.squarepath")
                        .platformContentSymbolStyle()
                }
            }

            Section {
                NavigationLink(value: CommunityLibraryDestination.guidelines) {
                    Label(ProfileDashboardCopy.communityGuidelines, systemImage: "doc.text.fill")
                        .platformContentSymbolStyle()
                }
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.communityLibraryTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}
