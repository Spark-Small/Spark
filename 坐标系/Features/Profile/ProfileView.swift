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
    @State private var showCreateAccount = false
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    profileSection
                    activityShelf
                    publishedShelf
                    circlesShelf
                    buddiesEntry
                }
            }
            .contentMargins(.top, PlatformMetrics.sectionHeaderSpacing, for: .scrollContent)
            .contentMargins(.bottom, PlatformMetrics.sectionSpacing, for: .scrollContent)
            .background(PlatformSurface.groupedPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    accountMenu
                }
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
            .sheet(isPresented: $showCreateAccount) {
                ProfileCreateAccountSheet(session: app.auth)
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
        VStack(alignment: .leading, spacing: PlatformMetrics.sectionHeaderSpacing) {
            Button {
                showEditProfile = true
            } label: {
                profileIdentityRow
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityHint("打开个人资料编辑")

            HStack(spacing: PlatformMetrics.railCardSpacing) {
                NavigationLink {
                    ProfileMembershipView()
                } label: {
                    Text("开通会员")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)

                NavigationLink {
                    ProfileWalletView()
                } label: {
                    Text("我的钱包")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .buttonBorderShape(.capsule)
            .controlSize(.large)
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }

    @ViewBuilder
    private var accountMenu: some View {
        Menu {
            if app.auth.isGuest {
                Button("手机号创建账号", systemImage: "phone") {
                    showCreateAccount = true
                }
                Button("使用 Apple 创建", systemImage: "apple.logo") {
                    app.auth.signInDemoApple()
                }
                Button("使用微信创建", systemImage: "message") {
                    app.auth.signInDemoWeChat()
                }
            } else {
                Button("编辑个人资料", systemImage: "person.crop.circle") {
                    showEditProfile = true
                }
                NavigationLink {
                    ProfileSettingsView()
                } label: {
                    Label("账号设置", systemImage: "lock.shield")
                }
            }
        } label: {
            Text(app.auth.isGuest ? "创建账号" : "账号")
        }
        .accessibilityHint(app.auth.isGuest ? "选择创建账号方式" : "打开账号操作")
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
        Array(community.myPosts.prefix(3))
    }

    private var publishedActivitiesPreview: [Activity] {
        Array(
            activities.hostedActivities
                .sorted { $0.date > $1.date }
                .prefix(max(0, 3 - publishedPostsPreview.count))
        )
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
                            PlatformActivityCompactCard(
                                photo: activity.coverPhoto,
                                badge: activities.isHost(activity) ? "主办中" : ActivityCardStatus.joined,
                                title: activity.title,
                                metaLine: Formatters.activityEventTime(from: activity.date)
                            )
                            .platformProfileActivityHistoryRailFrame()
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
            if publishedPostsPreview.isEmpty && publishedActivitiesPreview.isEmpty {
                profileShelfEmptyState(
                    title: "还没有发布内容",
                    systemImage: "square.and.pencil",
                    description: "发社区分享或发起活动后，这里会显示最近内容。"
                )
            } else {
                VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
                    ForEach(publishedPostsPreview) { post in
                        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                            NavigationLink(value: post) {
                                ProfilePublishedLibraryLabel(
                                    title: post.messageText,
                                    subtitle: "公开 · \(postShelfMetaLine(for: post))"
                                ) {
                                    CommunityRemotePhoto(ref: post.coverPhoto)
                                }
                            }
                            .buttonStyle(.plain)

                            Menu {
                                ShareLink(item: post.shareText) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.body.weight(.semibold))
                            }
                            .buttonStyle(.plain)
                            .controlSize(.large)
                            .accessibilityLabel("更多，\(post.messageText)")
                        }
                    }

                    ForEach(publishedActivitiesPreview) { activity in
                        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
                            NavigationLink(value: activity.id) {
                                ProfilePublishedLibraryLabel(
                                    title: activity.title,
                                    subtitle: "公开 · 活动 · \(Formatters.activityEventTime(from: activity.date))"
                                ) {
                                    CommunityRemotePhoto(ref: activity.coverPhoto)
                                        .activityZoomTransitionSource(
                                            id: activity.id,
                                            in: zoomNamespace,
                                            clip: .rail
                                        )
                                }
                            }
                            .buttonStyle(.plain)

                            Menu {
                                ShareLink(item: activityShareText(for: activity)) {
                                    Label("分享", systemImage: "square.and.arrow.up")
                                }
                            } label: {
                                Image(systemName: "ellipsis")
                                    .font(.body.weight(.semibold))
                            }
                            .buttonStyle(.plain)
                            .controlSize(.large)
                            .accessibilityLabel("更多，\(activity.title)")
                        }
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
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
                                            .platformSymbolStyle(.multicolor)
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
                    .platformContentSymbolStyle()
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

    private func activityShareText(for activity: Activity) -> String {
        "【坐标系·活动】\(activity.title)\n\(Formatters.activityEventTime(from: activity.date))\n\(activity.location)"
    }
}

#Preview {
    ProfileView()
}

private enum ActivityLibraryDestination: Hashable {
    case joined
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
