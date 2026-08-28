//
//  ProfileContentLibraryView.swift
//  坐标系
//
//  「我的」发布凭证夹与活动收藏列表。
//

import SwiftUI

// MARK: - Published (分享 / 发起)

/// 「我发起的」：分享 / 活动双分段凭证夹。
struct ProfilePublishedLibraryView: View {
    enum Segment: String, CaseIterable, Identifiable, Hashable {
        case posts = "分享"
        case activities = "活动"

        var id: String { rawValue }
    }

    @Environment(ActivitiesModel.self) private var activities
    @Environment(CommunityModel.self) private var community
    @Namespace private var zoomNamespace
    @State private var segment: Segment

    init(initialSegment: Segment = .posts) {
        _segment = State(initialValue: initialSegment)
    }

    private var snapshot: CreatorInsightsSnapshot {
        CreatorInsightsService.snapshot(activities: activities, community: community)
    }

    var body: some View {
        List {
            Section {
                Picker("发布类型", selection: $segment) {
                    ForEach(Segment.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            } footer: {
                Text("创作凭证仅在 App 内展示；互动数据基于本机统计。")
            }

            Section {
                switch segment {
                case .posts:
                    postsRows
                case .activities:
                    activitiesRows
                }
            } header: {
                Text(segment == .posts ? "分享凭证夹" : "发起凭证夹")
            }
        }
        .profileSecondaryListChrome()
        .navigationTitle(ProfileDashboardCopy.activityHosted)
        .navigationBarTitleDisplayMode(.inline)
        .activityZoomNavigationDestinationIfNeeded(fallback: zoomNamespace)
        .onAppear {
            if snapshot.posts.isEmpty, !snapshot.activities.isEmpty {
                segment = .activities
            }
        }
    }

    @ViewBuilder
    private var postsRows: some View {
        let items = snapshot.posts
        if items.isEmpty {
            ContentUnavailableView(
                "还没有发布分享",
                systemImage: "square.and.pencil",
                description: Text("在社区发帖后，内容会出现在这里。")
            )
            .listRowBackground(Color.clear)
        } else {
            ForEach(items) { item in
                NavigationLink(value: item.post) {
                    ProfilePublishedCredentialCard(
                        kind: .post,
                        title: item.post.messageText,
                        metaLine: "\(ProfileLibraryCopy.postMetaLine(for: item.post)) · \(item.metricLine)",
                        photo: item.post.coverPhoto,
                        idHint: item.post.id.uuidString
                    )
                }
                .platformProfileCredentialCardRow()
            }
        }
    }

    @ViewBuilder
    private var activitiesRows: some View {
        let items = snapshot.activities
        if items.isEmpty {
            ContentUnavailableView(
                "还没有发起活动",
                systemImage: "flag",
                description: Text("发起活动后会出现在这里。")
            )
            .listRowBackground(Color.clear)
        } else {
            ForEach(items) { item in
                ActivityZoomNavigationLink(
                    activity: item.activity,
                    namespace: zoomNamespace
                ) {
                    ProfilePublishedCredentialCard(
                        kind: .hostedActivity,
                        title: item.activity.title,
                        metaLine: "\(Formatters.activityEventTime(from: item.activity.date)) · \(item.metricLine)",
                        photo: item.activity.coverPhoto,
                        idHint: item.activity.id.uuidString
                    )
                }
                .platformProfileCredentialCardRow()
            }
        }
    }
}

// MARK: - Favorite activities (embeddable)

struct ProfileFavoriteActivitiesLibraryView: View {
    @Environment(ActivitiesModel.self) private var model
    @Environment(AppModel.self) private var app
    @Namespace private var zoomNamespace

    var body: some View {
        List {
            if model.favoriteActivities.isEmpty {
                Section {
                    ContentUnavailableView(
                        "还没有收藏活动",
                        systemImage: "bookmark",
                        description: Text("在活动详情里点收藏，想去的局会出现在这里。")
                    )
                    .listRowBackground(Color.clear)

                    Button("去发现活动") {
                        app.selectedTab = .activities
                    }
                    .activityPrimaryCTA(controlSize: .large)
                    .buttonSizing(.flexible)
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(model.favoriteActivities) { activity in
                    ActivityZoomNavigationLink(
                        activity: activity,
                        namespace: zoomNamespace
                    ) {
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
        .profileSecondaryListChrome()
        .navigationTitle("收藏的活动")
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
