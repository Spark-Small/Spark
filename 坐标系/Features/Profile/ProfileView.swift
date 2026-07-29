//
//  ProfileView.swift
//  坐标系
//
//  「我的」根页：资料卡 + 个人内容库预览 + 设置。
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(CommunityModel.self) private var community

    @State private var showEditProfile = false
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    profileSection
                    activityShelf
                    publishedShelf
                    favoritesShelf
                    circlesShelf
                    buddiesEntry
                }
            }
            .contentMargins(.top, PlatformMetrics.sectionHeaderSpacing, for: .scrollContent)
            .contentMargins(.bottom, PlatformMetrics.sectionSpacing, for: .scrollContent)
            .background(PlatformSurface.groupedPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ProfileSettingsView()
                    } label: {
                        Label("设置", systemImage: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileSheet(user: Binding(
                    get: { app.user },
                    set: { updated in app.updateProfile(updated) }
                ))
            }
            .activityZoomNavigationDestination(namespace: zoomNamespace)
            .navigationDestination(for: CommunityPost.self) { post in
                CommunityPostDetailView(postID: post.id)
            }
            .navigationDestination(for: InterestCircle.self) { circle in
                ProfileCircleDetailView(circle: circle)
            }
            .navigationDestination(for: PublishedDestination.self) { destination in
                ProfilePublishedView(initialSegment: destination.segment)
            }
            .navigationDestination(for: ActivityLibraryDestination.self) { destination in
                switch destination {
                case .joined:
                    ActivityTripsView(presentation: .pushed, initialSegment: .joined)
                }
            }
            .navigationDestination(for: FavoritesDestination.self) { _ in
                ProfileFavoritesView()
            }
            .navigationDestination(for: CircleDestination.self) { _ in
                ProfileCirclesListView()
            }
            .navigationDestination(for: BuddiesDestination.self) { _ in
                ProfileBuddiesView()
            }
            .buddyOrgJoinChrome(
                buddies: buddies,
                openConversation: { app.openMessages(conversationID: $0) }
            )
        }
    }

    private var profileSection: some View {
        Button {
            showEditProfile = true
        } label: {
            profileIdentityRow
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .accessibilityHint("打开个人资料编辑")
        .padding(.horizontal, PlatformMetrics.contentInset)
    }

    private var joinedActivitiesPreview: [Activity] {
        activities.joinedActivities
            .filter { !activities.isHost($0) && !$0.isPast }
            .sorted { $0.date < $1.date }
    }

    private var hostedActivitiesPreview: [Activity] {
        activities.hostedActivities
            .filter { !$0.isPast }
            .sorted { $0.date < $1.date }
    }

    private var publishedPostsPreview: [CommunityPost] {
        Array(community.myPosts.prefix(6))
    }

    private var favoriteActivitiesPreview: [Activity] {
        Array(activities.favoriteActivities.prefix(6))
    }

    private var favoritePostsPreview: [CommunityPost] {
        Array(community.bookmarkedPosts.prefix(6))
    }

    private var joinedCirclesPreview: [InterestCircle] {
        Array(buddies.joinedCircles.prefix(8))
    }

    private var activityPreview: [Activity] {
        let unique = Dictionary(
            grouping: joinedActivitiesPreview + hostedActivitiesPreview,
            by: \.id
        )
        return Array(
            unique.values
                .compactMap(\.first)
                .sorted { $0.date < $1.date }
                .prefix(8)
        )
    }

    private var activityShelf: some View {
        DiscoverBrowseSection(
            title: "我的活动",
            onSeeAll: {
                path.append(ActivityLibraryDestination.joined)
            }
        ) {
            if activityPreview.isEmpty {
                profileShelfEmptyState(
                    title: "还没有活动行程",
                    systemImage: "calendar",
                    description: "参加或发起活动后，这里会优先展示未结束的内容。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(activityPreview) { activity in
                        ActivityZoomNavigationLink(
                            activity: activity,
                            namespace: zoomNamespace,
                            clip: .rail
                        ) {
                            ProfileLibraryShelfCard(
                                title: activity.title,
                                subtitle: Formatters.activityEventTime(from: activity.date),
                                badge: activities.isHost(activity) ? "主办中" : ActivityCardStatus.joined
                            ) {
                                CommunityRemotePhoto(ref: activity.coverPhoto)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                    }
                }
            }
        }
    }

    private var publishedShelf: some View {
        DiscoverBrowseSection(
            title: "我的发布",
            onSeeAll: {
                path.append(PublishedDestination(segment: .posts))
            }
        ) {
            if publishedPostsPreview.isEmpty && hostedActivitiesPreview.isEmpty {
                profileShelfEmptyState(
                    title: "还没有发布内容",
                    systemImage: "square.and.pencil",
                    description: "发社区分享或发起活动后，这里会显示最近内容。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(publishedPostsPreview) { post in
                        NavigationLink(value: post) {
                            ProfileLibraryShelfCard(
                                title: post.messageText,
                                subtitle: postShelfMetaLine(for: post),
                                badge: "分享"
                            ) {
                                CommunityRemotePhoto(ref: post.coverPhoto)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                        .buttonStyle(.plain)
                    }

                    ForEach(Array(hostedActivitiesPreview.prefix(max(0, 6 - publishedPostsPreview.count)))) { activity in
                        ActivityZoomNavigationLink(
                            activity: activity,
                            namespace: zoomNamespace,
                            clip: .rail
                        ) {
                            ProfileLibraryShelfCard(
                                title: activity.title,
                                subtitle: Formatters.activityEventTime(from: activity.date),
                                badge: "活动"
                            ) {
                                CommunityRemotePhoto(ref: activity.coverPhoto)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                    }
                }
            }
        }
    }

    private var favoritesShelf: some View {
        DiscoverBrowseSection(
            title: "收藏",
            onSeeAll: {
                path.append(FavoritesDestination.root)
            }
        ) {
            if favoriteActivitiesPreview.isEmpty && favoritePostsPreview.isEmpty {
                profileShelfEmptyState(
                    title: "还没有收藏内容",
                    systemImage: "bookmark",
                    description: "在活动或社区里点收藏后，这里会保留最近内容。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(favoriteActivitiesPreview) { activity in
                        ActivityZoomNavigationLink(
                            activity: activity,
                            namespace: zoomNamespace,
                            clip: .rail
                        ) {
                            ProfileLibraryShelfCard(
                                title: activity.title,
                                subtitle: Formatters.activityEventTime(from: activity.date),
                                badge: "活动"
                            ) {
                                CommunityRemotePhoto(ref: activity.coverPhoto)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                    }

                    ForEach(favoritePostsPreview) { post in
                        NavigationLink(value: post) {
                            ProfileLibraryShelfCard(
                                title: post.messageText,
                                subtitle: postShelfMetaLine(for: post),
                                badge: "分享"
                            ) {
                                CommunityRemotePhoto(ref: post.coverPhoto)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var circlesShelf: some View {
        DiscoverBrowseSection(
            title: "我的圈子",
            onSeeAll: {
                path.append(CircleDestination.root)
            }
        ) {
            if joinedCirclesPreview.isEmpty {
                profileShelfEmptyState(
                    title: "还没有加入圈子",
                    systemImage: "person.3",
                    description: "去搭子页找到合适的兴趣组织，加入后可在这里快速回看。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(joinedCirclesPreview) { circle in
                        NavigationLink(value: circle) {
                            ProfileLibraryShelfCard(
                                title: circle.name,
                                subtitle: "\(circle.topic) · \(circle.memberCount) 人",
                                badge: "已加入"
                            ) {
                                Color.accentColor.opacity(0.14)
                                    .overlay {
                                        Image(systemName: circle.systemImage)
                                            .font(.title2)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(Color.accentColor)
                                    }
                            }
                            .platformProfileLibraryRailFrame()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var buddiesEntry: some View {
        DiscoverBrowseSection(
            title: "我的陪玩",
            onSeeAll: {
                path.append(BuddiesDestination.root)
            }
        ) {
            NavigationLink(value: BuddiesDestination.root) {
                Label("查看我的陪玩", systemImage: "person.2")
                    .font(.body.weight(.medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, PlatformMetrics.contentInset)
                    .padding(.vertical, PlatformConversationListRow.verticalInset)
                    .background(PlatformSurface.elevated, in: PlatformMetrics.cardShape)
                    .padding(.horizontal, PlatformMetrics.contentInset)
            }
            .buttonStyle(.plain)
        }
    }

    private var profileIdentityRow: some View {
        HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
            ProfileAvatarView(
                user: app.user,
                completion: ProfileCompletion.ratio(for: app.user)
            )

            VStack(alignment: .leading, spacing: PlatformConversationListRow.textToSecondarySpacing) {
                Text(app.user.name)
                    .font(.title2.weight(.bold))
                Text(app.user.handle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if app.auth.isGuest {
                    Text("访客")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            [app.user.name, app.user.handle, app.auth.isGuest ? "访客" : nil]
                .compactMap { $0 }
                .filter { !$0.isEmpty }
                .joined(separator: "，")
        )
    }

    @ViewBuilder
    private func profileShelfEmptyState(
        title: String,
        systemImage: String,
        description: String
    ) -> some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity)
        .padding(.horizontal, PlatformMetrics.contentInset)
    }

    private func postShelfMetaLine(for post: CommunityPost) -> String {
        let parts = [
            Formatters.conversationListTime(from: post.postedAt),
            "赞 \(post.likeCount)",
            "评 \(post.commentCount)"
        ]
        return parts.joined(separator: " · ")
    }
}

#Preview {
    ProfileView()
}

private enum ActivityLibraryDestination: Hashable {
    case joined
}

private enum FavoritesDestination: Hashable {
    case root
}

private enum CircleDestination: Hashable {
    case root
}

private enum BuddiesDestination: Hashable {
    case root
}

private struct PublishedDestination: Hashable {
    var segment: ProfilePublishedView.Segment
}

private struct ProfileLibraryShelfCard<Media: View>: View {
    let title: String
    let subtitle: String
    var badge: String? = nil
    @ViewBuilder var media: () -> Media

    var body: some View {
        ZStack {
            media()
                .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fill)
                .clipped()

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.78)],
                startPoint: .center,
                endPoint: .bottom
            )

            if let badge, !badge.isEmpty {
                PlatformMediaCaptionBadge(title: badge)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: PlatformMetrics.cardInfoSpacing) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(PlatformMetrics.captionBadgeInset)
        }
        .aspectRatio(PlatformMetrics.profileLibraryCardAspectRatio, contentMode: .fit)
        .clipShape(PlatformMetrics.posterShape)
        .contentShape(PlatformMetrics.posterShape)
        .colorScheme(.dark)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title)，\(subtitle)")
    }
}
