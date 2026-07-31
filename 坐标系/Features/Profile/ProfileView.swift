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
                    ProfileActivityCredentialsShelf {
                        path.append(ProfileRoute.activityLibrary)
                    }
                    ProfileBookingCredentialsShelf(
                        onSeeAll: { path.append(ProfileRoute.buddies) },
                        onOpenBooking: { path.append(ProfileRoute.booking($0)) }
                    )
                    publishedShelf
                    circlesShelf
                }
            }
            .contentMargins(.top, PlatformMetrics.sectionHeaderSpacing, for: .scrollContent)
            .contentMargins(.bottom, PlatformMetrics.sectionSpacing, for: .scrollContent)
            .background(PlatformSurface.groupedPage)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { profileToolbar }
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
            .circleDetailNavigationDestination()
            .navigationDestination(for: ProfileRoute.self, destination: profileDestination)
            .buddyOrgJoinChrome(
                buddies: buddies,
                openConversation: { app.openMessages(conversationID: $0) }
            )
            .platformTabBarHiddenWhenPushed(path.isEmpty)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var profileToolbar: some ToolbarContent {
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

    // MARK: - Navigation

    @ViewBuilder
    private func profileDestination(_ route: ProfileRoute) -> some View {
        switch route {
        case .activityLibrary:
            ProfileActivityCredentialsView()
        case .published(let segment):
            ProfilePublishedView(initialSegment: segment)
        case .circles:
            ProfileCirclesListView()
        case .buddies:
            ProfileBuddiesView()
        case .booking(let id):
            BookingCredentialExpandedView(recordID: id)
        }
    }

    // MARK: - Identity

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

            commercialButtons
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }

    private var commercialButtons: some View {
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

    // MARK: - Previews

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

    // MARK: - Shelves

    private var publishedShelf: some View {
        DiscoverBrowseSection(
            title: "我的发布",
            onSeeAll: { path.append(ProfileRoute.published(.posts)) }
        ) {
            if publishedPostsPreview.isEmpty && publishedActivitiesPreview.isEmpty {
                ProfileShelfEmptyState(
                    title: "还没有发布内容",
                    systemImage: "square.and.pencil",
                    description: "发社区分享或发起活动后，这里会显示最近内容。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(publishedShelfItems) { item in
                        publishedCredentialRailItem(item)
                    }
                }
            }
        }
        .activityZoomSlot("profile-published")
    }

    private enum PublishedShelfItem: Identifiable {
        case post(CommunityPost)
        case activity(Activity)

        var id: String {
            switch self {
            case .post(let post): "post-\(post.id)"
            case .activity(let activity): "activity-\(activity.id)"
            }
        }
    }

    private var publishedShelfItems: [PublishedShelfItem] {
        var items: [PublishedShelfItem] = publishedPostsPreview.map(PublishedShelfItem.post)
        items += publishedActivitiesPreview.map(PublishedShelfItem.activity)
        return Array(items.prefix(6))
    }

    @ViewBuilder
    private func publishedCredentialRailItem(_ item: PublishedShelfItem) -> some View {
        switch item {
        case .post(let post):
            HStack(alignment: .top, spacing: PlatformMetrics.railCardSpacing) {
                NavigationLink(value: post) {
                    ProfilePublishedCredentialCard(
                        kind: .post,
                        title: post.messageText,
                        metaLine: ProfileLibraryCopy.postMetaLine(for: post),
                        photo: post.coverPhoto,
                        idHint: post.id.uuidString
                    )
                    .platformProfileWalletPassRailFrame()
                }
                .buttonStyle(.plain)

                ProfilePublishedShareMenu(
                    shareText: post.shareText,
                    accessibilityTitle: post.messageText
                )
            }
        case .activity(let activity):
            HStack(alignment: .top, spacing: PlatformMetrics.railCardSpacing) {
                ActivityZoomNavigationLink(
                    activity: activity,
                    namespace: zoomNamespace
                ) {
                    ProfilePublishedCredentialCard(
                        kind: .hostedActivity,
                        title: activity.title,
                        metaLine: "活动 · \(Formatters.activityEventTime(from: activity.date))",
                        photo: activity.coverPhoto,
                        idHint: activity.id.uuidString
                    )
                    .platformProfileWalletPassRailFrame()
                }

                ProfilePublishedShareMenu(
                    shareText: ProfileLibraryCopy.activityShareText(for: activity),
                    accessibilityTitle: activity.title
                )
            }
        }
    }

    private var circlesShelf: some View {
        DiscoverBrowseSection(
            title: "我的圈子",
            onSeeAll: { path.append(ProfileRoute.circles) }
        ) {
            if joinedCirclesPreview.isEmpty {
                ProfileShelfEmptyState(
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
                                subtitle: "\(circle.topic) · \(circle.memberCount) 人"
                            ) {
                                ProfileCircleShelfCover(systemImage: circle.systemImage)
                            }
                            .platformProfileLibraryRailFrame()
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Routes

private enum ProfileRoute: Hashable {
    case activityLibrary
    case published(ProfilePublishedView.Segment)
    case circles
    case buddies
    case booking(BuddyBookingRecord.ID)
}

#Preview {
    ProfileView()
}
