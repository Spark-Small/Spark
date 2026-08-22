//
//  ProfileView.swift
//  坐标系
//

import SwiftUI

struct ProfileView: View {
    @Environment(AppModel.self) private var app
    @Environment(CommunityModel.self) private var community
    @Environment(BuddiesModel.self) private var buddies
    @AppStorage("profile.membership.active") private var membershipActive = false

    @State private var showEditProfile = false
    @State private var showCreateAccount = false
    @State private var createAccountReason = GuestAccessGate.identityReason
    @State private var youthBlockedMessage: String?
    @State private var showSettingsFromTip = false
    @State private var confirmSignOut = false
    @State private var recentBrowseRecords = ProfileRecentBrowseStore.shared.items()
    @State private var navigation = TabNavigationState()
    @Namespace private var activityZoomNamespace

    private var photoVerified: Bool {
        PhotoVerificationStore.shared.isVerified(for: app.user.name)
    }

    var body: some View {
        @Bindable var navigation = navigation

        NavigationStack(path: $navigation.path) {
            profileList
                .platformTabRootToolbar { tabToolbar }
                .profileRootPresentations(
                    app: app,
                    createAccountReason: createAccountReason,
                    showEditProfile: $showEditProfile,
                    showCreateAccount: $showCreateAccount,
                    showSettingsFromTip: $showSettingsFromTip,
                    youthBlockedMessage: $youthBlockedMessage,
                    confirmSignOut: $confirmSignOut
                )
                .profileRootDestinations(
                    navigation: navigation,
                    buddies: buddies,
                    app: app,
                    activityZoomNamespace: activityZoomNamespace
                )
                .onAppear {
                    recentBrowseRecords = ProfileRecentBrowseStore.shared.items()
                    consumePendingProfileNavigation()
                }
                .onChange(of: app.pendingProfileRoute) { _, route in
                    guard route != nil else { return }
                    consumePendingProfileNavigation()
                }
        }
        .tabNavigationState(navigation)
    }

    // MARK: - List

    private var profileList: some View {
        List {
            lifecycleTipSection
            identitySection
            accountServicesSection
            activitiesSection
            ordersSection
            recentBrowseSection
            logoutSection
        }
        .platformTabRootListChrome(title: ProfileDashboardCopy.rootTitle, compactSections: true)
    }

    // MARK: - Sections

    @ViewBuilder
    private var lifecycleTipSection: some View {
        if let tip = lifecycleTips.first {
            Section {
                Text(tip.detail)
                    .foregroundStyle(.secondary)
                if tip.id == "privacy" {
                    Button("去设置") { showSettingsFromTip = true }
                        .buttonStyle(.plain)
                        .foregroundStyle(.primary)
                }
                Button("关闭", role: .cancel) {
                    ProductLifecycleStore.shared.dismissTip(tip.id)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            } header: {
                Label(tip.title, systemImage: tip.systemImage)
                    .platformContentSymbolStyle()
            }
        }
    }

    private var identitySection: some View {
        Section {
            VStack {
                Button(action: openIdentity) {
                    HStack(alignment: .center, spacing: PlatformConversationListRow.imageToTextPadding) {
                        ProfileAvatarView(
                            user: app.user,
                            completion: ProfileCompletion.ratio(for: app.user)
                        )

                        VStack(alignment: .leading) {
                            Text(app.user.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Text(app.user.handle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            if app.auth.isGuest {
                                Text(ProfileDashboardCopy.guestHint)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            } else {
                                TrustCredentialBadgeStrip(
                                    photoVerified: photoVerified,
                                    isMember: membershipActive
                                )
                            }
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint(
                    app.auth.isGuest ? "创建账号后编辑个人资料" : "打开个人资料编辑"
                )
                .accessibilityLabel(identityAccessibilityLabel)

                ProfileSocialStatsRow(
                    postCount: ProfileSocialStats.postCount(for: app.user.name, community: community),
                    followingCount: ProfileSocialStats.followingCount(for: app.user.name, app: app),
                    fansCount: ProfileSocialStats.fansCount(for: app.user.name, app: app)
                )
            }
            .listRowSeparator(.hidden)
        }
    }

    private var accountServicesSection: some View {
        Section {
            ProfileMembershipAdContentView(
                isActive: membershipActive,
                onTap: {
                    openCommerce { navigation.path.append(ProfileRoute.membership) }
                }
            )

            ProfileFormGatedRow(
                title: ProfileDashboardCopy.trustEntry,
                systemImage: "checkmark.shield.fill"
            ) {
                navigation.path.append(ProfileRoute.trust)
            }

            ProfileFormGatedRow(
                title: ProfileDashboardCopy.walletEntry,
                systemImage: "creditcard.fill"
            ) {
                openCommerce { navigation.path.append(ProfileRoute.wallet) }
            }

            ProfileFormGatedRow(
                title: ProfileDashboardCopy.becomeCompanion,
                systemImage: "person.badge.plus"
            ) {
                openCommerce { navigation.path.append(ProfileRoute.becomeCompanion) }
            }
        } header: {
            Text(ProfileDashboardCopy.reputationSectionTitle)
        }
    }

    private var ordersSection: some View {
        Section {
            ForEach(ProfileOrderShortcutFilter.allCases) { filter in
                NavigationLink(value: ProfileRoute.orders(filter)) {
                    LabeledContent {
                        let count = orderShortcutCounts.count(for: filter)
                        if count > 0 {
                            Text("\(count)")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    } label: {
                        Label(filter.title, systemImage: filter.systemImage)
                            .platformContentSymbolStyle()
                    }
                }
            }
        } header: {
            Text(ProfileDashboardCopy.ordersTitle)
        }
    }

    private var activitiesSection: some View {
        Section {
            NavigationLink(value: ProfileRoute.hostedActivities) {
                Label(ProfileDashboardCopy.activityHosted, systemImage: "calendar.badge.plus")
                    .platformContentSymbolStyle()
            }
            NavigationLink(value: ProfileRoute.joinedActivities) {
                Label(ProfileDashboardCopy.activityJoined, systemImage: "calendar")
                    .platformContentSymbolStyle()
            }
            NavigationLink(value: ProfileRoute.bookingCredentials) {
                LabeledContent {
                    let count = buddies.actionableBookingCount
                    if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.bookingCredentials, systemImage: "ticket.fill")
                        .platformContentSymbolStyle()
                }
            }
            NavigationLink(value: ProfileRoute.activityInvites) {
                LabeledContent {
                    let count = buddies.inviteRecords.filter { $0.status == .pending }.count
                    if count > 0 {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } label: {
                    Label(ProfileDashboardCopy.activityInvites, systemImage: "paperplane.fill")
                        .platformContentSymbolStyle()
                }
            }
            NavigationLink(value: ProfileRoute.favoriteActivities) {
                Label(ProfileDashboardCopy.activityFavorites, systemImage: "star.fill")
                    .platformContentSymbolStyle()
            }
            NavigationLink(value: ProfileRoute.browseHistory) {
                Label(ProfileDashboardCopy.activityHistory, systemImage: "clock.arrow.circlepath")
                    .platformContentSymbolStyle()
            }
        } header: {
            Text(ProfileDashboardCopy.activitiesTitle)
        }
    }

    private var recentBrowseSection: some View {
        Section {
            ProfileRecentBrowseShelf(
                records: recentBrowseRecords,
                zoomNamespace: activityZoomNamespace,
                onSeeAll: { navigation.path.append(ProfileRoute.browseHistory) }
            )
            .platformFormRelatedRailRow()
        }
    }

    @ViewBuilder
    private var logoutSection: some View {
        if !app.auth.isGuest {
            Section {
                Button(ProfileDashboardCopy.logout, role: .destructive) {
                    confirmSignOut = true
                }
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var tabToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            NavigationLink {
                ProfileSettingsView()
                    .platformHiddenTabBar()
            } label: {
                Image(systemName: "gearshape.fill")
            }
            .accessibilityLabel("设置")
        }
    }

    // MARK: - Derived data

    private var identityAccessibilityLabel: String {
        var parts = [app.user.name, app.user.handle]
        if app.auth.isGuest {
            parts.append("访客")
        } else {
            parts.append(
                [
                    photoVerified ? "认证已通过" : "认证未认证",
                    membershipActive ? "会员已开通" : "会员未开通"
                ].joined(separator: " · ")
            )
        }
        return parts.filter { !$0.isEmpty }.joined(separator: "，")
    }

    private var orderShortcutCounts: ProfileOrderShortcutCounts {
        ProfileOrderShortcutCounts.compute(
            activityOrders: ActivityPaymentStore.allOrders(),
            bookingRecords: buddies.bookingRecords
        )
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

    private func consumePendingProfileNavigation() {
        guard let route = app.pendingProfileRoute else { return }
        app.pendingProfileRoute = nil
        app.pendingBookingID = nil
        navigation.path.append(route)
    }
}

// MARK: - Stack chrome

private extension View {
    func profileRootPresentations(
        app: AppModel,
        createAccountReason: String,
        showEditProfile: Binding<Bool>,
        showCreateAccount: Binding<Bool>,
        showSettingsFromTip: Binding<Bool>,
        youthBlockedMessage: Binding<String?>,
        confirmSignOut: Binding<Bool>
    ) -> some View {
        sheet(isPresented: showEditProfile) {
            EditProfileSheet(user: Binding(
                get: { app.user },
                set: { updated in app.updateProfile(updated) }
            ))
            .platformHiddenTabBar()
        }
        .sheet(isPresented: showCreateAccount) {
            ProfileCreateAccountSheet(
                session: app.auth,
                reason: createAccountReason
            )
            .platformHiddenTabBar()
        }
        .navigationDestination(isPresented: showSettingsFromTip) {
            ProfileSettingsView()
                .platformHiddenTabBar()
        }
        .alert("青少年模式", isPresented: youthBlockedMessage.isOptionalPresented) {
            Button("好的", role: .cancel) { youthBlockedMessage.wrappedValue = nil }
        } message: {
            Text(youthBlockedMessage.wrappedValue ?? "")
        }
        .alert(ProfileDashboardCopy.logoutConfirmTitle, isPresented: confirmSignOut) {
            Button(ProfileDashboardCopy.logout, role: .destructive) {
                Task { await app.signOutLocally() }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text(ProfileDashboardCopy.logoutConfirmMessage)
        }
    }

    func profileRootDestinations(
        navigation: TabNavigationState,
        buddies: BuddiesModel,
        app: AppModel,
        activityZoomNamespace: Namespace.ID
    ) -> some View {
        navigationDestination(for: CommunityPost.self) { post in
            CommunityPostDetailView(postID: post.id)
                .platformHiddenTabBar()
        }
        .circleBrowseStackChrome(
            buddies: buddies,
            openCircle: { navigation.openCircle($0) },
            openConversation: { app.openMessages(conversationID: $0) }
        )
        .activityZoomNavigationDestination(namespace: activityZoomNamespace)
        .navigationDestination(for: ProfileRoute.self) { route in
            ProfileRouteDestination(route: route)
                .platformHiddenTabBar()
        }
    }
}

private extension Binding where Value == String? {
    var isOptionalPresented: Binding<Bool> {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresented in
                if !isPresented { wrappedValue = nil }
            }
        )
    }
}

#Preview {
    ProfileView()
}
