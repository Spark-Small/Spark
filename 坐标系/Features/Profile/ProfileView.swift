//
//  ProfileView.swift
//  坐标系
//
//  「我的」根页：资料卡 + 凭证架 + 内容库预览 + 设置。
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(ActivitiesModel.self) private var activities
    @Environment(BuddiesModel.self) private var buddies
    @Environment(CommunityModel.self) private var community
    @AppStorage("profile.membership.active") private var membershipActive = false

    @State private var showEditProfile = false
    @State private var showCreateAccount = false
    @State private var createAccountReason = GuestAccessGate.identityReason
    @State private var youthBlockedMessage: String?
    @State private var showSettingsFromTip = false
    @State private var path = NavigationPath()
    @Namespace private var zoomNamespace

    private var photoVerified: Bool {
        _ = PhotoVerificationStore.shared.isVerified
        return PhotoVerificationStore.shared.isVerified(for: app.user.name)
    }
    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PlatformMetrics.sectionSpacing) {
                    if let tip = lifecycleTips.first {
                        ProductLifecycleBanner(
                            tip: tip,
                            onDismiss: {
                                ProductLifecycleStore.shared.dismissTip(tip.id)
                            },
                            onOpenSettings: tip.id == "privacy"
                                ? { showSettingsFromTip = true }
                                : nil
                        )
                    }
                    profileSection
                    ProfileActivityCredentialsShelf {
                        path.append(ProfileRoute.activityLibrary)
                    }
                    ProfileBookingCredentialsShelf(
                        onSeeAll: { path.append(ProfileRoute.buddies) },
                        onOpenBooking: { path.append(ProfileRoute.booking($0)) }
                    )
                    contentLibraryShelf
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
                ProfileCreateAccountSheet(
                    session: app.auth,
                    reason: createAccountReason
                )
            }
            .navigationDestination(isPresented: $showSettingsFromTip) {
                ProfileSettingsView()
            }
            .alert(
                "青少年模式",
                isPresented: Binding(
                    get: { youthBlockedMessage != nil },
                    set: { if !$0 { youthBlockedMessage = nil } }
                )
            ) {
                Button("好的", role: .cancel) { youthBlockedMessage = nil }
            } message: {
                Text(youthBlockedMessage ?? "")
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
            Button {
                path.append(ProfileRoute.orders)
            } label: {
                Label("我的订单", systemImage: "list.bullet.rectangle")
            }
            .accessibilityLabel("我的订单")
        }
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                ProfileSettingsView()
            } label: {
                Label("设置", systemImage: "gearshape")
            }
        }
    }

    // MARK: - Navigation

    @ViewBuilder
    private func profileDestination(_ route: ProfileRoute) -> some View {
        switch route {
        case .activityLibrary:
            ProfileActivityCredentialsView()
        case .contentLibrary:
            ProfileContentLibraryView()
        case .membership:
            ProfileMembershipView()
        case .wallet:
            ProfileWalletView()
        case .orders:
            ProfileOrdersView()
        case .trust:
            TrustPrivateDashboardView()
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
            HStack(alignment: .top, spacing: PlatformConversationListRow.imageToTextPadding) {
                Button {
                    openIdentity()
                } label: {
                    profileIdentityRow
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .accessibilityHint(
                    app.auth.isGuest ? "创建账号后编辑个人资料" : "打开个人资料编辑"
                )

                Button {
                    path.append(ProfileRoute.trust)
                } label: {
                    Image(systemName: "checkmark.seal")
                        .font(.body.weight(.semibold))
                        .platformContentSymbolStyle()
                }
                .buttonStyle(.plain)
                .padding(.top, 6)
                .accessibilityLabel("我的信誉")
            }

            commercialButtons
        }
        .padding(.horizontal, PlatformMetrics.contentInset)
    }

    private var commercialButtons: some View {
        HStack(spacing: PlatformMetrics.railCardSpacing) {
            Button {
                openCommerce { path.append(ProfileRoute.membership) }
            } label: {
                Text(membershipActive ? "会员中心" : "开通会员")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.primary)

            Button {
                openCommerce { path.append(ProfileRoute.wallet) }
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
                    .lineLimit(1)
                Text(app.user.handle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if app.auth.isGuest {
                    Text("访客 · 创建账号解锁交易与资料")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PlatformStatus.warning)
                } else {
                    TrustCredentialBadgeStrip(
                        photoVerified: photoVerified,
                        isMember: membershipActive
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(identityAccessibilityLabel)
    }

    private var identityAccessibilityLabel: String {
        var parts = [app.user.name, app.user.handle]
        if app.auth.isGuest {
            parts.append("访客")
        } else {
            parts.append(photoVerified ? "形象认证已通过" : "形象认证未认证")
            parts.append(membershipActive ? "会员已开通" : "会员未开通")
        }
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
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

    private var contentLibraryShelf: some View {
        DiscoverBrowseSection(
            title: "我的内容库",
            onSeeAll: { path.append(ProfileRoute.contentLibrary) }
        ) {
            if publishedPostsPreview.isEmpty && publishedActivitiesPreview.isEmpty {
                ProfileShelfEmptyState(
                    title: "内容库还是空的",
                    systemImage: "square.stack.3d.up",
                    description: "发布、收藏的活动与分享、赞过与转发，都会收在「我的内容库」。"
                )
            } else {
                DiscoverHorizontalRail {
                    ForEach(publishedShelfItems) { item in
                        publishedCredentialRailItem(item)
                    }
                }
            }
        }
        .activityZoomSlot("profile-content-library")
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

    // MARK: - Guest gates

    private func openIdentity() {
        createAccountReason = GuestAccessGate.identityReason
        if GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) {
            showEditProfile = true
        }
    }

    private func openCommerce(_ action: () -> Void) {
        if YouthModePreference.isEnabled {
            youthBlockedMessage = GuestAccessGate.youthCommerceReason
            return
        }
        createAccountReason = GuestAccessGate.commerceReason
        if GuestAccessGate.allow(app.auth, presentCreateAccount: $showCreateAccount) {
            action()
        }
    }

    private func presentCreateAccount(reason: String) {
        createAccountReason = reason
        showCreateAccount = true
    }

    private var lifecycleTips: [ProductLifecycleTip] {
        let hasOrders = !ActivityPaymentStore.allOrders().isEmpty
            || !buddies.bookingRecords.isEmpty
        return ProductLifecycleStore.shared.activeTips(
            isGuest: app.auth.isGuest,
            profileComplete: ProfileCompletion.ratio(for: app.user) >= 0.8,
            hasOrders: hasOrders
        )
    }
}

// MARK: - Routes

private enum ProfileRoute: Hashable {
    case activityLibrary
    case contentLibrary
    case membership
    case wallet
    case orders
    case trust
    case circles
    case buddies
    case booking(BuddyBookingRecord.ID)
}

#Preview {
    ProfileView()
}
