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
            ActivityTripsView(presentation: .pushed, initialSegment: .joined)
        case .published(let segment):
            ProfilePublishedView(initialSegment: segment)
        case .circles:
            ProfileCirclesListView()
        case .buddies:
            ProfileBuddiesView()
        case .booking(let id):
            BuddyBookingDetailView(recordID: id)
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

    /// 未结束：我参加的 + 我主办的（二者互斥）。
    private var activityPreview: [Activity] {
        let joined = activities.joinedActivities
            .filter { !activities.isHost($0) && !$0.isPast }
        let hosted = activities.hostedActivities
            .filter { !$0.isPast }
        return Array((joined + hosted).sorted { $0.date < $1.date }.prefix(8))
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

    private var bookingPreview: [BuddyBookingRecord] {
        let terminalStatuses: Set<BookingOrderStatus> = [.completed, .refunded, .cancelled]
        return Array(
            buddies.bookingRecords
                .sorted { lhs, rhs in
                    let lhsIsTerminal = terminalStatuses.contains(lhs.status)
                    let rhsIsTerminal = terminalStatuses.contains(rhs.status)
                    if lhsIsTerminal != rhsIsTerminal {
                        return !lhsIsTerminal
                    }
                    return lhsIsTerminal
                        ? lhs.scheduledAt > rhs.scheduledAt
                        : lhs.scheduledAt < rhs.scheduledAt
                }
                .prefix(8)
        )
    }

    // MARK: - Shelves

    private var activityShelf: some View {
        DiscoverBrowseSection(
            title: "我的活动",
            onSeeAll: { path.append(ProfileRoute.activityLibrary) }
        ) {
            if activityPreview.isEmpty {
                ProfileShelfEmptyState(
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
                                title: activity.title,
                                metaLine: Formatters.activityEventTime(from: activity.date)
                            )
                            .platformProfileActivityHistoryRailFrame()
                        }
                    }
                }
            }
        }
        .activityZoomSlot("profile-activities")
    }

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
                VStack(spacing: PlatformMetrics.sectionHeaderSpacing) {
                    ForEach(publishedPostsPreview) { post in
                        publishedPostRow(post)
                    }
                    ForEach(publishedActivitiesPreview) { activity in
                        publishedActivityRow(activity)
                    }
                }
                .padding(.horizontal, PlatformMetrics.contentInset)
            }
        }
        .activityZoomSlot("profile-published")
    }

    private func publishedPostRow(_ post: CommunityPost) -> some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            NavigationLink(value: post) {
                ProfilePublishedLibraryLabel(
                    title: post.messageText,
                    subtitle: "公开 · \(ProfileLibraryCopy.postMetaLine(for: post))"
                ) {
                    CommunityRemotePhoto(ref: post.coverPhoto)
                }
            }
            .buttonStyle(.plain)

            ProfilePublishedShareMenu(
                shareText: post.shareText,
                accessibilityTitle: post.messageText
            )
        }
    }

    private func publishedActivityRow(_ activity: Activity) -> some View {
        HStack(spacing: PlatformConversationListRow.imageToTextPadding) {
            ActivityZoomNavigationLink(
                activity: activity,
                namespace: zoomNamespace
            ) {
                ProfilePublishedLibraryLabel(
                    title: activity.title,
                    subtitle: "公开 · 活动 · \(Formatters.activityEventTime(from: activity.date))"
                ) {
                    CommunityRemotePhoto(ref: activity.coverPhoto)
                }
            }

            ProfilePublishedShareMenu(
                shareText: ProfileLibraryCopy.activityShareText(for: activity),
                accessibilityTitle: activity.title
            )
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

    private var buddiesEntry: some View {
        DiscoverBrowseSection(
            title: "我的陪玩",
            onSeeAll: { path.append(ProfileRoute.buddies) }
        ) {
            if bookingPreview.isEmpty {
                ProfileShelfEmptyState(
                    title: "还没有陪玩预约",
                    systemImage: "person.badge.clock",
                    description: "在搭子页预约陪玩后，这里会展示最近订单。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(bookingPreview) { record in
                        NavigationLink(value: ProfileRoute.booking(record.id)) {
                            ProfileBookingShelfCard(
                                record: record,
                                photo: buddies.item(for: record.companionNickname)?.profile.coverPhoto
                            )
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
